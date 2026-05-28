param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("test", "build", "demoTokens", "router", "hook", "pool", "swap", "largeSwap", "read", "verify")]
    [string]$Step,

    [ValidateSet("mainnet", "testnet")]
    [string]$Network = "mainnet"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Import-DotEnv {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Host "No .env file found. Copy .env.example to .env and fill the required values." -ForegroundColor Yellow
        return
    }

    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line.Length -eq 0 -or $line.StartsWith("#")) {
            return
        }

        $parts = $line.Split("=", 2)
        if ($parts.Length -ne 2) {
            return
        }

        $name = $parts[0].Trim()
        $value = $parts[1].Trim().Trim('"').Trim("'")
        if ($name.Length -gt 0 -and $value.Length -gt 0) {
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

function Require-Env {
    param([string[]]$Names)

    foreach ($name in $Names) {
        $value = [Environment]::GetEnvironmentVariable($name, "Process")
        if ([string]::IsNullOrWhiteSpace($value)) {
            throw "Missing required env var: $name"
        }
    }
}

function Require-V4-Core {
    if ($Network -eq "testnet") {
        Require-Env @("V4_POOL_MANAGER", "V4_POSITION_MANAGER")
    }
}

function Invoke-Forge {
    param([string[]]$ForgeArgs)

    Write-Host "> forge $($ForgeArgs -join ' ')" -ForegroundColor Cyan
    & forge @ForgeArgs
}

Import-DotEnv ".env"
$env:PATH = "$env:USERPROFILE\.foundry\bin;$env:PATH"

if ($Network -eq "mainnet") {
    if ([string]::IsNullOrWhiteSpace($env:V4_POOL_MANAGER)) {
        $env:V4_POOL_MANAGER = "0x360e68faccca8ca495c1b759fd9eee466db9fb32"
    }
    if ([string]::IsNullOrWhiteSpace($env:V4_POSITION_MANAGER)) {
        $env:V4_POSITION_MANAGER = "0xcf1eafc6928dc385a342e7c6491d371d2871458b"
    }
}

function Get-RpcUrl {
    $rpcEnv = if ($Network -eq "mainnet") { "XLAYER_MAINNET_RPC" } else { "XLAYER_TESTNET_RPC" }
    $rpcUrl = [Environment]::GetEnvironmentVariable($rpcEnv, "Process")
    if ([string]::IsNullOrWhiteSpace($rpcUrl)) {
        throw "Missing $rpcEnv"
    }
    return $rpcUrl
}

switch ($Step) {
    "test" {
        Invoke-Forge -ForgeArgs @("test")
    }
    "build" {
        Invoke-Forge -ForgeArgs @("build")
    }
    "demoTokens" {
        Require-Env @("PRIVATE_KEY")
        $RpcUrl = Get-RpcUrl
        Invoke-Forge -ForgeArgs @("script", "script/00_DeployDemoTokens.s.sol", "--tc", "DeployDemoTokensScript", "--rpc-url", $RpcUrl, "--private-key", $env:PRIVATE_KEY, "--broadcast")
    }
    "router" {
        Require-Env @("PRIVATE_KEY")
        $RpcUrl = Get-RpcUrl
        Invoke-Forge -ForgeArgs @("script", "script/00_DeployHookmateRouter.s.sol", "--tc", "DeployHookmateRouterScript", "--rpc-url", $RpcUrl, "--private-key", $env:PRIVATE_KEY, "--broadcast")
    }
    "hook" {
        Require-Env @("PRIVATE_KEY")
        Require-V4-Core
        $RpcUrl = Get-RpcUrl
        Invoke-Forge -ForgeArgs @("script", "script/00_DeployHook.s.sol", "--tc", "DeployHookScript", "--rpc-url", $RpcUrl, "--private-key", $env:PRIVATE_KEY, "--broadcast")
    }
    "pool" {
        Require-Env @("PRIVATE_KEY", "V4_POOL_MANAGER", "V4_POSITION_MANAGER", "HOOK_ADDRESS", "TOKEN0", "TOKEN1")
        $RpcUrl = Get-RpcUrl
        Invoke-Forge -ForgeArgs @("script", "script/01_CreatePoolAndAddLiquidity.s.sol", "--tc", "CreatePoolAndAddLiquidityScript", "--rpc-url", $RpcUrl, "--private-key", $env:PRIVATE_KEY, "--broadcast")
    }
    "swap" {
        Require-Env @("PRIVATE_KEY", "V4_POOL_MANAGER", "V4_SWAP_ROUTER", "HOOK_ADDRESS", "TOKEN0", "TOKEN1")
        $RpcUrl = Get-RpcUrl
        Invoke-Forge -ForgeArgs @("script", "script/03_Swap.s.sol", "--tc", "SwapScript", "--rpc-url", $RpcUrl, "--private-key", $env:PRIVATE_KEY, "--broadcast")
    }
    "largeSwap" {
        Require-Env @("PRIVATE_KEY", "V4_POOL_MANAGER", "V4_SWAP_ROUTER", "HOOK_ADDRESS", "TOKEN0", "TOKEN1")
        $RpcUrl = Get-RpcUrl
        $env:SWAP_AMOUNT = "5000000000000000000"
        Invoke-Forge -ForgeArgs @("script", "script/03_Swap.s.sol", "--tc", "SwapScript", "--rpc-url", $RpcUrl, "--private-key", $env:PRIVATE_KEY, "--broadcast")
    }
    "read" {
        Require-Env @("HOOK_ADDRESS", "TOKEN0", "TOKEN1")
        Require-V4-Core
        $RpcUrl = Get-RpcUrl
        Invoke-Forge -ForgeArgs @("script", "script/04_ReadPixelGuard.s.sol", "--tc", "ReadPixelGuardScript", "--rpc-url", $RpcUrl)
    }
    "verify" {
        Require-Env @("OKLINK_API_KEY", "HOOK_ADDRESS")
        Require-V4-Core
        $RpcUrl = Get-RpcUrl
        $chain = if ($Network -eq "mainnet") { "XLAYER" } else { "XLAYER_TESTNET" }
        $verifyUrl = "https://www.oklink.com/api/v5/explorer/contract/verify-source-code-plugin/$chain"
        $constructorArgs = & cast abi-encode "constructor(address)" $env:V4_POOL_MANAGER
        Invoke-Forge -ForgeArgs @(
            "verify-contract",
            "--rpc-url", $RpcUrl,
            "--verifier-url", $verifyUrl,
            "--verifier-api-key", $env:OKLINK_API_KEY,
            "--constructor-args", $constructorArgs,
            "--watch",
            $env:HOOK_ADDRESS,
            "src/PixelGuardHook.sol:PixelGuardHook"
        )
    }
}
