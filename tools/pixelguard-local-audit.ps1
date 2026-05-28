param(
    [switch]$IncludeDeploymentReadiness
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$env:PATH = "$env:USERPROFILE\.foundry\bin;$env:PATH"

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Command
    )

    Write-Host ""
    Write-Host "== $Name ==" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

Invoke-Step "forge build" {
    forge build
}

Invoke-Step "forge test" {
    forge test
}

Invoke-Step "forge fmt --check" {
    forge fmt --check
}

Invoke-Step "PowerShell syntax" {
    $tokens = $null
    $errors = @()
    Get-ChildItem tools -Filter *.ps1 | ForEach-Object {
        $fileErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$fileErrors)
        if ($fileErrors) {
            $errors += $fileErrors
        }
    }

    if ($errors.Count -gt 0) {
        $errors | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
        exit 1
    }

    Write-Host "PowerShell syntax OK"
}

Invoke-Step "submission pack generation" {
    powershell -ExecutionPolicy Bypass -File tools\pixelguard-submit-pack.ps1
}

Invoke-Step "stale Counter reference check" {
    $results = rg "Counter" src test script README.md .env.example
    if ($LASTEXITCODE -eq 0) {
        Write-Host $results -ForegroundColor Red
        exit 1
    }

    if ($LASTEXITCODE -eq 1) {
        $global:LASTEXITCODE = 0
        Write-Host "No stale Counter references in submission code paths"
    }
}

if ($IncludeDeploymentReadiness) {
    Invoke-Step "deployment readiness" {
        powershell -ExecutionPolicy Bypass -File tools\pixelguard-readiness.ps1
    }
}

Write-Host ""
Write-Host "PixelGuard local audit passed." -ForegroundColor Green
