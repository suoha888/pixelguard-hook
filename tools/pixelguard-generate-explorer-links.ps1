param(
    [ValidateSet("mainnet", "testnet")]
    [string]$Network = "mainnet",
    [string]$ResultsPath = "docs/submission/deployment-results.md"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Read-Results {
    param([string]$Path)

    $values = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line.StartsWith("- ")) {
            return
        }

        $parts = $line.Substring(2).Split(":", 2)
        if ($parts.Length -eq 2) {
            $values[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
    return $values
}

function Update-Field {
    param(
        [string[]]$Lines,
        [string]$Field,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $Lines
    }

    $pattern = "^- $([regex]::Escape($Field)):\s*$"
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match $pattern) {
            $Lines[$i] = "- ${Field}: $Value"
            break
        }
    }
    return $Lines
}

function Is-Address {
    param([string]$Value)
    return $Value -match '^0x[0-9a-fA-F]{40}$'
}

function Is-TxHash {
    param([string]$Value)
    return $Value -match '^0x[0-9a-fA-F]{64}$'
}

if (-not (Test-Path $ResultsPath)) {
    throw "Missing deployment results file: $ResultsPath"
}

$base = if ($Network -eq "mainnet") { "https://www.oklink.com/xlayer" } else { "https://www.oklink.com/xlayer-test" }
$values = Read-Results $ResultsPath
$lines = [string[]](Get-Content $ResultsPath)

$hook = $values["PixelGuard Hook"]
$normalSwap = $values["Demo swap tx"]
$largeSwap = $values["Guarded large swap tx"]
$poolTx = $values["Pool initialize/add-liquidity tx"]

if (Is-Address $hook) {
    $lines = Update-Field $lines "OKX Explorer Hook URL" "$base/address/$hook"
} else {
    Write-Host "PixelGuard Hook is empty or invalid; hook explorer URL not generated." -ForegroundColor Yellow
}

$poolOrSwapTx = $largeSwap
if (-not (Is-TxHash $poolOrSwapTx)) {
    $poolOrSwapTx = $normalSwap
}
if (-not (Is-TxHash $poolOrSwapTx)) {
    $poolOrSwapTx = $poolTx
}

if (Is-TxHash $poolOrSwapTx) {
    $lines = Update-Field $lines "OKX Explorer pool/swap URL" "$base/tx/$poolOrSwapTx"
} else {
    Write-Host "No valid pool/swap transaction hash found; pool/swap explorer URL not generated." -ForegroundColor Yellow
}

Set-Content -LiteralPath $ResultsPath -Value $lines -Encoding utf8

Write-Host "Updated explorer links in $ResultsPath where possible." -ForegroundColor Green
Write-Host "Explorer base used: $base" -ForegroundColor Cyan
