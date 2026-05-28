param(
    [string]$ZipPath = "dist/PixelGuard-Hook-submission.zip"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Test-Path $ZipPath)) {
    throw "Missing release zip: $ZipPath"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

$required = @(
    "README.md",
    "JUDGES.md",
    ".github/workflows/test.yml",
    "src/PixelGuardHook.sol",
    "test/PixelGuardHook.t.sol",
    "script/00_DeployHook.s.sol",
    "script/01_CreatePoolAndAddLiquidity.s.sol",
    "script/03_Swap.s.sol",
    "script/04_ReadPixelGuard.s.sol",
    "tools/pixelguard-deploy.ps1",
    "tools/pixelguard-chain-check.ps1",
    "tools/pixelguard-wallet-check.ps1",
    "tools/pixelguard-finalize-submission.ps1",
    "tools/pixelguard-readiness.ps1",
    "docs/submission/generated-submit-pack.md",
    "docs/submission/final-quickstart-zh.md",
    "docs/brand/pixelguard-avatar.svg",
    "docs/brand/pixelguard-banner.svg",
    ".env.example"
)

$forbiddenPatterns = @(
    '(^|/)\.env$',
    '(^|/)cache/',
    '(^|/)out/',
    '(^|/)broadcast/',
    '(^|/)dist/',
    '(^|/)docs/superpowers/',
    '(^|/)node_modules/',
    '(^|/)lib/'
)

$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $ZipPath).Path)
try {
    $names = @($zip.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
    $missing = New-Object System.Collections.Generic.List[string]
    $forbidden = New-Object System.Collections.Generic.List[string]
    $secretLike = New-Object System.Collections.Generic.List[string]

    foreach ($item in $required) {
        if ($names -notcontains $item) {
            $missing.Add($item)
        }
    }

    foreach ($name in $names) {
        foreach ($pattern in $forbiddenPatterns) {
            if ($name -match $pattern) {
                $forbidden.Add($name)
            }
        }
    }

    foreach ($entry in $zip.Entries) {
        if ($entry.Length -eq 0 -or $entry.Length -gt 1MB) {
            continue
        }

        $stream = $entry.Open()
        try {
            $reader = New-Object System.IO.StreamReader($stream)
            $text = $reader.ReadToEnd()
            if ($text -match '(?m)^PRIVATE_KEY\s*=\s*(0x)?[0-9a-fA-F]{64}\s*$') {
                $secretLike.Add("$($entry.FullName): PRIVATE_KEY-like value")
            }
            if ($text -match '-----BEGIN (RSA |EC |OPENSSH |)PRIVATE KEY-----') {
                $secretLike.Add("$($entry.FullName): private key block")
            }
        } finally {
            if ($reader) {
                $reader.Dispose()
            } else {
                $stream.Dispose()
            }
        }
    }

    if ($missing.Count -gt 0) {
        Write-Host "Release zip is missing required files:" -ForegroundColor Red
        $missing | ForEach-Object { Write-Host "- $_" }
    }

    if ($forbidden.Count -gt 0) {
        Write-Host "Release zip contains forbidden paths:" -ForegroundColor Red
        $forbidden | Sort-Object -Unique | ForEach-Object { Write-Host "- $_" }
    }

    if ($secretLike.Count -gt 0) {
        Write-Host "Release zip contains secret-looking content:" -ForegroundColor Red
        $secretLike | Sort-Object -Unique | ForEach-Object { Write-Host "- $_" }
    }

    if ($missing.Count -gt 0 -or $forbidden.Count -gt 0 -or $secretLike.Count -gt 0) {
        exit 1
    }

    Write-Host "Release zip verification passed." -ForegroundColor Green
} finally {
    $zip.Dispose()
}
