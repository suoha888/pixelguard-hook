param(
    [ValidateSet("mainnet", "testnet")]
    [string]$Network = "mainnet",
    [string]$EnvPath = ".env",
    [switch]$AllowPreDeployment
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

function Get-Value {
    param(
        [hashtable]$Values,
        [string]$Name,
        [string]$Fallback = ""
    )

    if ($Values.ContainsKey($Name) -and -not [string]::IsNullOrWhiteSpace($Values[$Name])) {
        return $Values[$Name]
    }
    return $Fallback
}

function Check-ContractCode {
    param(
        [string]$Name,
        [string]$Address,
        [string]$RpcUrl,
        [System.Collections.Generic.List[string]]$Errors,
        [System.Collections.Generic.List[string]]$Warnings,
        [bool]$Optional
    )

    if ([string]::IsNullOrWhiteSpace($Address)) {
        if ($Optional) {
            $Warnings.Add("$Name is empty")
        } else {
            $Errors.Add("$Name is empty")
        }
        return
    }

    if (-not (Is-Address $Address)) {
        $Errors.Add("$Name is not a valid EVM address")
        return
    }

    $code = & cast code $Address --rpc-url $RpcUrl
    if ($LASTEXITCODE -ne 0) {
        $Errors.Add("cast code failed for $Name")
        return
    }

    if ([string]::IsNullOrWhiteSpace($code) -or $code.Trim() -eq "0x") {
        if ($Optional) {
            $Warnings.Add("$Name has no code at $Address")
        } else {
            $Errors.Add("$Name has no code at $Address")
        }
        return
    }

    Write-Host "$Name code found at $Address" -ForegroundColor Green
}

$values = Read-DotEnv $EnvPath
$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path $EnvPath)) {
    $errors.Add("Missing $EnvPath")
}

$rpcName = if ($Network -eq "mainnet") { "XLAYER_MAINNET_RPC" } else { "XLAYER_TESTNET_RPC" }
$rpcUrl = Get-Value $values $rpcName
if ([string]::IsNullOrWhiteSpace($rpcUrl)) {
    $errors.Add("Missing $rpcName")
}

if ($errors.Count -eq 0) {
    $expectedChainId = if ($Network -eq "mainnet") { "196" } else { "1952" }
    $chainId = & cast chain-id --rpc-url $rpcUrl
    if ($LASTEXITCODE -ne 0) {
        $errors.Add("cast chain-id failed")
    } elseif ($chainId.Trim() -ne $expectedChainId) {
        $errors.Add("RPC chain id is $($chainId.Trim()), expected $expectedChainId for $Network")
    } else {
        Write-Host "RPC chain id OK: $expectedChainId" -ForegroundColor Green
    }
}

if ($errors.Count -eq 0) {
    $poolManagerDefault = if ($Network -eq "mainnet") { "0x360e68faccca8ca495c1b759fd9eee466db9fb32" } else { "" }
    $positionManagerDefault = if ($Network -eq "mainnet") { "0xcf1eafc6928dc385a342e7c6491d371d2871458b" } else { "" }

    $poolManager = Get-Value $values "V4_POOL_MANAGER" $poolManagerDefault
    $positionManager = Get-Value $values "V4_POSITION_MANAGER" $positionManagerDefault
    $token0 = Get-Value $values "TOKEN0"
    $token1 = Get-Value $values "TOKEN1"
    $router = Get-Value $values "V4_SWAP_ROUTER"
    $hook = Get-Value $values "HOOK_ADDRESS"

    Check-ContractCode "V4_POOL_MANAGER" $poolManager $rpcUrl $errors $warnings $false
    Check-ContractCode "V4_POSITION_MANAGER" $positionManager $rpcUrl $errors $warnings $false
    Check-ContractCode "TOKEN0" $token0 $rpcUrl $errors $warnings $AllowPreDeployment.IsPresent
    Check-ContractCode "TOKEN1" $token1 $rpcUrl $errors $warnings $AllowPreDeployment.IsPresent
    Check-ContractCode "V4_SWAP_ROUTER" $router $rpcUrl $errors $warnings $AllowPreDeployment.IsPresent
    Check-ContractCode "HOOK_ADDRESS" $hook $rpcUrl $errors $warnings $AllowPreDeployment.IsPresent

    if (Is-Address $hook) {
        $suffix = [Convert]::ToUInt16($hook.Substring(38, 4), 16)
        if (($suffix -band 0x0080) -eq 0 -or ($suffix -band 0x0040) -eq 0) {
            $errors.Add("HOOK_ADDRESS does not include both beforeSwap and afterSwap flags")
        } else {
            Write-Host "HOOK_ADDRESS flags include beforeSwap and afterSwap" -ForegroundColor Green
        }

        if ($errors.Count -eq 0) {
            $owner = & cast call $hook "hookOwner()(address)" --rpc-url $rpcUrl
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Hook owner: $owner" -ForegroundColor Green
            } else {
                $warnings.Add("Could not read hookOwner from HOOK_ADDRESS")
                $global:LASTEXITCODE = 0
            }
        }
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "Warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "- $warning"
    }
}

if ($errors.Count -gt 0) {
    Write-Host "Errors:" -ForegroundColor Red
    foreach ($errorItem in $errors) {
        Write-Host "- $errorItem"
    }
    exit 1
}

Write-Host "PixelGuard chain check passed for $Network." -ForegroundColor Green
