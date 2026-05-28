param(
    [ValidateSet("mainnet", "testnet")]
    [string]$Network = "mainnet",
    [string]$EnvPath = ".env"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$env:PATH = "$env:USERPROFILE\.foundry\bin;$env:PATH"

function Read-DotEnv {
    param([string]$Path)

    $values = @{}
    if (-not (Test-Path $Path)) {
        return $values
    }

    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line.Length -eq 0 -or $line.StartsWith("#")) {
            return
        }

        $parts = $line.Split("=", 2)
        if ($parts.Length -eq 2) {
            $values[$parts[0].Trim()] = $parts[1].Trim().Trim('"').Trim("'")
        }
    }

    return $values
}

function Is-Address {
    param([string]$Value)
    return $Value -match '^0x[0-9a-fA-F]{40}$'
}

function Get-EnvValue {
    param(
        [hashtable]$Values,
        [string]$Name
    )

    if ($Values.ContainsKey($Name) -and -not [string]::IsNullOrWhiteSpace($Values[$Name])) {
        return $Values[$Name]
    }
    return ""
}

$values = Read-DotEnv $EnvPath
$errors = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path $EnvPath)) {
    $errors.Add("Missing $EnvPath")
}

$rpcName = if ($Network -eq "mainnet") { "XLAYER_MAINNET_RPC" } else { "XLAYER_TESTNET_RPC" }
$rpcUrl = Get-EnvValue $values $rpcName
$privateKey = Get-EnvValue $values "PRIVATE_KEY"

if ([string]::IsNullOrWhiteSpace($rpcUrl)) {
    $errors.Add("Missing $rpcName")
}
if ([string]::IsNullOrWhiteSpace($privateKey)) {
    $errors.Add("Missing PRIVATE_KEY")
}

if ($errors.Count -gt 0) {
    Write-Host "Errors:" -ForegroundColor Red
    foreach ($errorItem in $errors) {
        Write-Host "- $errorItem"
    }
    exit 1
}

$deployer = (& cast wallet address --private-key $privateKey).Trim()
if ($LASTEXITCODE -ne 0 -or -not (Is-Address $deployer)) {
    throw "Could not derive deployer address from PRIVATE_KEY"
}

Write-Host "Deployer address: $deployer" -ForegroundColor Cyan

$nativeBalance = (& cast balance $deployer --rpc-url $rpcUrl).Trim()
if ($LASTEXITCODE -eq 0) {
    Write-Host "Native OKB balance (wei): $nativeBalance"
}

$token0 = Get-EnvValue $values "TOKEN0"
$token1 = Get-EnvValue $values "TOKEN1"
$router = Get-EnvValue $values "V4_SWAP_ROUTER"
$positionManager = Get-EnvValue $values "V4_POSITION_MANAGER"
if ([string]::IsNullOrWhiteSpace($positionManager) -and $Network -eq "mainnet") {
    $positionManager = "0xcf1eafc6928dc385a342e7c6491d371d2871458b"
}

foreach ($item in @(@("TOKEN0", $token0), @("TOKEN1", $token1))) {
    $name = $item[0]
    $token = $item[1]
    if (-not (Is-Address $token)) {
        Write-Host "$name not set or invalid; skipping token balance checks." -ForegroundColor Yellow
        continue
    }

    $balance = (& cast call $token "balanceOf(address)(uint256)" $deployer --rpc-url $rpcUrl).Trim()
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$name balance (wei units): $balance"
    }

    if (Is-Address $router) {
        $allowance = (& cast call $token "allowance(address,address)(uint256)" $deployer $router --rpc-url $rpcUrl).Trim()
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$name allowance to V4_SWAP_ROUTER: $allowance"
        }
    }

    if (Is-Address $positionManager) {
        $allowanceToPositionManager = (& cast call $token "allowance(address,address)(uint256)" $deployer $positionManager --rpc-url $rpcUrl).Trim()
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$name direct allowance to V4_POSITION_MANAGER: $allowanceToPositionManager"
        }
    }
}

Write-Host "PixelGuard wallet check complete. Private key was not printed." -ForegroundColor Green
