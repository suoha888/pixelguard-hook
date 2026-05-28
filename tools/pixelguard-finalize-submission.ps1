param(
    [ValidateSet("mainnet", "testnet")]
    [string]$Network = "mainnet",
    [string]$ResultsPath = "docs/submission/deployment-results.md",
    [switch]$AllowSocialPending,
    [switch]$RunLocalAudit
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Command,
        [switch]$AllowFailure
    )

    Write-Host ""
    Write-Host "== $Name ==" -ForegroundColor Cyan
    & $Command
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        if ($AllowFailure) {
            Write-Host "$Name reported incomplete state. Continue reviewing the output above." -ForegroundColor Yellow
            $global:LASTEXITCODE = 0
        } else {
            throw "$Name failed with exit code $code"
        }
    }
}

if ($RunLocalAudit) {
    Invoke-Step "local audit" {
        powershell -ExecutionPolicy Bypass -File tools\pixelguard-local-audit.ps1
    }
}

Invoke-Step "broadcast summary and inferred result fields" {
    powershell -ExecutionPolicy Bypass -File tools\pixelguard-broadcast-summary.ps1 -Network $Network -ResultsPath $ResultsPath -UpdateResults
}

Invoke-Step "explorer link generation" {
    powershell -ExecutionPolicy Bypass -File tools\pixelguard-generate-explorer-links.ps1 -Network $Network -ResultsPath $ResultsPath
}

Invoke-Step "submission pack generation" {
    powershell -ExecutionPolicy Bypass -File tools\pixelguard-submit-pack.ps1 -ResultsPath $ResultsPath
}

Invoke-Step "release bundle" {
    powershell -ExecutionPolicy Bypass -File tools\pixelguard-make-release-zip.ps1
}

Invoke-Step "release bundle verification" {
    powershell -ExecutionPolicy Bypass -File tools\pixelguard-verify-release-zip.ps1
}

if ($AllowSocialPending) {
    Invoke-Step "readiness check" {
        powershell -ExecutionPolicy Bypass -File tools\pixelguard-readiness.ps1 -ResultsPath $ResultsPath -AllowSocialPending
    } -AllowFailure
} else {
    Invoke-Step "readiness check" {
        powershell -ExecutionPolicy Bypass -File tools\pixelguard-readiness.ps1 -ResultsPath $ResultsPath
    } -AllowFailure
}

Write-Host ""
Write-Host "Finalize pass complete. Open docs/submission/generated-submit-pack.md for copy/paste text." -ForegroundColor Green
