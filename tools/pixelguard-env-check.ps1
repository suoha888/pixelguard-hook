param(
    [ValidateSet("mainnet", "testnet")]
    [string]$Network = "mainnet",
    [string]$EnvPath = ".env"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

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
        if ($parts.Length -ne 2) {
            return
        }

        $name = $parts[0].Trim()
        $value = $parts[1].Trim().Trim('"').Trim("'")
        $values[$name] = $value
    }

    return $values
}

function Is-Address {
    param([string]$Value)
    return $Value -match '^0x[0-9a-fA-F]{40}$'
}

function Is-PrivateKey {
    param([string]$Value)
    return $Value -match '^(0x)?[0-9a-fA-F]{64}$'
}

function Require-Value {
    param(
        [hashtable]$Values,
        [string]$Name,
        [System.Collections.Generic.List[string]]$Errors
    )

    if (-not $Values.ContainsKey($Name) -or [string]::IsNullOrWhiteSpace($Values[$Name])) {
        $Errors.Add("Missing $Name")
    }
}

function Check-Address {
    param(
        [hashtable]$Values,
        [string]$Name,
        [System.Collections.Generic.List[string]]$Errors,
        [System.Collections.Generic.List[string]]$Warnings
    )

    if (-not $Values.ContainsKey($Name) -or [string]::IsNullOrWhiteSpace($Values[$Name])) {
        $Warnings.Add("$Name is empty")
        return
    }

    if (-not (Is-Address $Values[$Name])) {
        $Errors.Add("$Name is not a valid EVM address")
    }
}

$values = Read-DotEnv $EnvPath
$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path $EnvPath)) {
    $errors.Add("Missing $EnvPath. Copy .env.example to .env first.")
}

$rpcName = if ($Network -eq "mainnet") { "XLAYER_MAINNET_RPC" } else { "XLAYER_TESTNET_RPC" }
Require-Value $values $rpcName $errors
Require-Value $values "PRIVATE_KEY" $errors

if ($values.ContainsKey("PRIVATE_KEY") -and -not [string]::IsNullOrWhiteSpace($values["PRIVATE_KEY"]) -and -not (Is-PrivateKey $values["PRIVATE_KEY"])) {
    $errors.Add("PRIVATE_KEY does not look like a 32-byte hex private key")
}

if (-not $values.ContainsKey("OKLINK_API_KEY") -or [string]::IsNullOrWhiteSpace($values["OKLINK_API_KEY"])) {
    $warnings.Add("OKLINK_API_KEY is empty. Deployment can run, but verification will fail.")
}

if ($Network -eq "mainnet") {
    if (-not $values.ContainsKey("V4_POOL_MANAGER") -or [string]::IsNullOrWhiteSpace($values["V4_POOL_MANAGER"])) {
        $warnings.Add("V4_POOL_MANAGER is empty. Scripts will use the known X Layer mainnet default.")
    } elseif ($values["V4_POOL_MANAGER"].ToLowerInvariant() -ne "0x360e68faccca8ca495c1b759fd9eee466db9fb32") {
        $warnings.Add("V4_POOL_MANAGER differs from the known X Layer mainnet address.")
    }

    if (-not $values.ContainsKey("V4_POSITION_MANAGER") -or [string]::IsNullOrWhiteSpace($values["V4_POSITION_MANAGER"])) {
        $warnings.Add("V4_POSITION_MANAGER is empty. Scripts will use the known X Layer mainnet default.")
    } elseif ($values["V4_POSITION_MANAGER"].ToLowerInvariant() -ne "0xcf1eafc6928dc385a342e7c6491d371d2871458b") {
        $warnings.Add("V4_POSITION_MANAGER differs from the known X Layer mainnet address.")
    }
} else {
    Check-Address $values "V4_POOL_MANAGER" $errors $warnings
    Check-Address $values "V4_POSITION_MANAGER" $errors $warnings
}

Check-Address $values "TOKEN0" $errors $warnings
Check-Address $values "TOKEN1" $errors $warnings

if ((Is-Address $values["TOKEN0"]) -and (Is-Address $values["TOKEN1"])) {
    if ($values["TOKEN0"].ToLowerInvariant() -eq $values["TOKEN1"].ToLowerInvariant()) {
        $errors.Add("TOKEN0 and TOKEN1 are the same address")
    }

    $tokenOrder = [string]::Compare($values["TOKEN0"].Substring(2), $values["TOKEN1"].Substring(2), $true, [Globalization.CultureInfo]::InvariantCulture)
    if ($tokenOrder -gt 0) {
        $warnings.Add("TOKEN0 is greater than TOKEN1. BaseScript sorts internally, but use the Recommended TOKEN0/TOKEN1 values for cleaner records.")
    }
}

if ($values.ContainsKey("V4_SWAP_ROUTER") -and -not [string]::IsNullOrWhiteSpace($values["V4_SWAP_ROUTER"])) {
    if (-not (Is-Address $values["V4_SWAP_ROUTER"])) {
        $errors.Add("V4_SWAP_ROUTER is not a valid EVM address")
    }
} else {
    $warnings.Add("V4_SWAP_ROUTER is empty. Deploy the Hookmate demo router before swap steps.")
}

if ($values.ContainsKey("HOOK_ADDRESS") -and -not [string]::IsNullOrWhiteSpace($values["HOOK_ADDRESS"])) {
    if (-not (Is-Address $values["HOOK_ADDRESS"])) {
        $errors.Add("HOOK_ADDRESS is not a valid EVM address")
    } else {
        $suffix = [Convert]::ToUInt16($values["HOOK_ADDRESS"].Substring(38, 4), 16)
        $beforeSwapFlag = 0x0080
        $afterSwapFlag = 0x0040
        if (($suffix -band $beforeSwapFlag) -eq 0 -or ($suffix -band $afterSwapFlag) -eq 0) {
            $errors.Add("HOOK_ADDRESS does not include both beforeSwap and afterSwap hook flags")
        }
    }
} else {
    $warnings.Add("HOOK_ADDRESS is empty. This is expected before the hook deployment step.")
}

if ($values.ContainsKey("SWAP_AMOUNT") -and -not [string]::IsNullOrWhiteSpace($values["SWAP_AMOUNT"])) {
    if ($values["SWAP_AMOUNT"] -notmatch '^\d+$') {
        $errors.Add("SWAP_AMOUNT must be an integer token amount in wei-style units")
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

Write-Host "PixelGuard environment check passed for $Network." -ForegroundColor Green
