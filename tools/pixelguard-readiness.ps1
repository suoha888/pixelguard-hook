param(
    [string]$ResultsPath = "docs/submission/deployment-results.md",
    [string]$GeneratedPackPath = "docs/submission/generated-submit-pack.md",
    [switch]$AllowSocialPending
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Test-Path $ResultsPath)) {
    throw "Missing deployment results file: $ResultsPath"
}

$required = @(
    "Network",
    "Chain ID",
    "RPC used",
    "Explorer",
    "Demo token A",
    "Demo token B",
    "Hookmate demo router",
    "PixelGuard Hook",
    "V4 PoolManager",
    "V4 PositionManager",
    "V4 PoolId",
    "Currency0",
    "Currency1",
    "Tick lower",
    "Tick upper",
    "Demo token deploy tx",
    "Hookmate router deploy tx",
    "Hook deploy tx",
    "Pool initialize/add-liquidity tx",
    "Demo swap tx",
    "Guarded large swap tx",
    "Latest receipt tokenId",
    "Latest receipt owner",
    "Latest receipt tokenURI captured",
    "Hook verification URL",
    "OKX Explorer Hook URL",
    "OKX Explorer pool/swap URL",
    "Demo video URL",
    "GitHub repository URL",
    "X account",
    "X submission post URL"
)

$social = @("X account", "X submission post URL")
$values = @{}

Get-Content $ResultsPath | ForEach-Object {
    if ($_ -match '^\s*-\s*([^:]+):\s*(.*)\s*$') {
        $values[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$missing = New-Object System.Collections.Generic.List[string]
$invalid = New-Object System.Collections.Generic.List[string]

function Test-Address {
    param([string]$Value)
    return $Value -match '^0x[0-9a-fA-F]{40}$'
}

function Test-Bytes32 {
    param([string]$Value)
    return $Value -match '^0x[0-9a-fA-F]{64}$'
}

function Test-Url {
    param([string]$Value)
    return $Value -match '^https?://'
}

function Test-Integer {
    param([string]$Value)
    return $Value -match '^-?\d+$'
}

function Add-Invalid {
    param(
        [string]$Field,
        [string]$Reason
    )
    $invalid.Add("${Field}: $Reason")
}

foreach ($field in $required) {
    if ($AllowSocialPending -and $social -contains $field) {
        continue
    }

    $value = $values[$field]
    if ([string]::IsNullOrWhiteSpace($value) -or $value -eq "[FILL]") {
        $missing.Add($field)
    }
}

$addressFields = @(
    "Demo token A",
    "Demo token B",
    "Hookmate demo router",
    "PixelGuard Hook",
    "V4 PoolManager",
    "V4 PositionManager",
    "Currency0",
    "Currency1",
    "Latest receipt owner"
)

foreach ($field in $addressFields) {
    $value = $values[$field]
    if (-not [string]::IsNullOrWhiteSpace($value) -and $value -ne "[FILL]" -and -not (Test-Address $value)) {
        Add-Invalid $field "expected 0x-prefixed 20-byte address"
    }
}

$hashFields = @(
    "V4 PoolId",
    "Demo token deploy tx",
    "Hookmate router deploy tx",
    "Hook deploy tx",
    "Pool initialize/add-liquidity tx",
    "Demo swap tx",
    "Guarded large swap tx"
)

foreach ($field in $hashFields) {
    $value = $values[$field]
    if (-not [string]::IsNullOrWhiteSpace($value) -and $value -ne "[FILL]" -and -not (Test-Bytes32 $value)) {
        Add-Invalid $field "expected 0x-prefixed 32-byte hash"
    }
}

$integerFields = @("Chain ID", "Tick lower", "Tick upper", "Latest receipt tokenId")
foreach ($field in $integerFields) {
    $value = $values[$field]
    if (-not [string]::IsNullOrWhiteSpace($value) -and $value -ne "[FILL]" -and -not (Test-Integer $value)) {
        Add-Invalid $field "expected integer"
    }
}

$urlFields = @(
    "RPC used",
    "Explorer",
    "Hook verification URL",
    "OKX Explorer Hook URL",
    "OKX Explorer pool/swap URL",
    "Demo video URL",
    "GitHub repository URL",
    "X submission post URL"
)

foreach ($field in $urlFields) {
    if ($AllowSocialPending -and $field -eq "X submission post URL") {
        continue
    }

    $value = $values[$field]
    if (-not [string]::IsNullOrWhiteSpace($value) -and $value -ne "[FILL]" -and -not (Test-Url $value)) {
        Add-Invalid $field "expected http(s) URL"
    }
}

if ((Test-Address $values["Demo token A"]) -and (Test-Address $values["Demo token B"]) -and
    $values["Demo token A"].ToLowerInvariant() -eq $values["Demo token B"].ToLowerInvariant()) {
    Add-Invalid "Demo token A/B" "token addresses must be different"
}

if ((Test-Address $values["Currency0"]) -and (Test-Address $values["Currency1"]) -and
    $values["Currency0"].ToLowerInvariant() -eq $values["Currency1"].ToLowerInvariant()) {
    Add-Invalid "Currency0/Currency1" "currency addresses must be different"
}

if ((Test-Integer $values["Tick lower"]) -and (Test-Integer $values["Tick upper"])) {
    if ([int]$values["Tick lower"] -ge [int]$values["Tick upper"]) {
        Add-Invalid "Tick range" "Tick lower must be less than Tick upper"
    }
}

if (-not [string]::IsNullOrWhiteSpace($values["Latest receipt tokenURI captured"]) -and
    $values["Latest receipt tokenURI captured"] -ne "[FILL]" -and
    -not $values["Latest receipt tokenURI captured"].StartsWith("data:application/json")) {
    Add-Invalid "Latest receipt tokenURI captured" "expected data:application/json tokenURI"
}

if (Test-Path $GeneratedPackPath) {
    $generatedPack = Get-Content -Raw -LiteralPath $GeneratedPackPath
    if ($generatedPack.Contains("[FILL]")) {
        Add-Invalid $GeneratedPackPath "generated submit pack still contains [FILL]"
    }
}

if ($missing.Count -gt 0) {
    Write-Host "PixelGuard submission is NOT ready. Missing fields:" -ForegroundColor Yellow
    foreach ($field in $missing) {
        Write-Host "- $field"
    }
}

if ($invalid.Count -gt 0) {
    Write-Host "PixelGuard submission has invalid-looking values:" -ForegroundColor Red
    foreach ($item in $invalid) {
        Write-Host "- $item"
    }
}

if ($missing.Count -gt 0 -or $invalid.Count -gt 0) {
    exit 1
}

Write-Host "PixelGuard submission fields look ready." -ForegroundColor Green
if ($AllowSocialPending) {
    Write-Host "Social fields were intentionally ignored because -AllowSocialPending was set." -ForegroundColor Yellow
}
