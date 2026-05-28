param(
    [string]$OutputPath = "dist/PixelGuard-Hook-submission.zip"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$rootResolved = (Resolve-Path ".").Path
$distDir = Join-Path $rootResolved "dist"
$stagingDir = Join-Path $distDir "pixelguard-release"
$outputResolved = Join-Path $rootResolved $OutputPath

function Assert-InRoot {
    param([string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($rootResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to touch path outside repository: $full"
    }
    return $full
}

$distDir = Assert-InRoot $distDir
$stagingDir = Assert-InRoot $stagingDir
$outputResolved = Assert-InRoot $outputResolved

New-Item -ItemType Directory -Force $distDir | Out-Null

if (Test-Path $stagingDir) {
    Remove-Item -LiteralPath $stagingDir -Recurse -Force
}
New-Item -ItemType Directory -Force $stagingDir | Out-Null

$items = @(
    ".env.example",
    ".github",
    ".gitignore",
    ".gitmodules",
    "foundry.lock",
    "foundry.toml",
    "JUDGES.md",
    "LICENSE",
    "README.md",
    "remappings.txt",
    "docs",
    "script",
    "src",
    "test",
    "tools"
)

foreach ($item in $items) {
    if (-not (Test-Path $item)) {
        continue
    }

    $destination = Join-Path $stagingDir $item
    $destinationParent = Split-Path -Parent $destination
    New-Item -ItemType Directory -Force $destinationParent | Out-Null
    Copy-Item -LiteralPath $item -Destination $destination -Recurse -Force
}

$internalDocs = Join-Path $stagingDir "docs\superpowers"
if (Test-Path $internalDocs) {
    Remove-Item -LiteralPath $internalDocs -Recurse -Force
}

if (Test-Path $outputResolved) {
    Remove-Item -LiteralPath $outputResolved -Force
}

Compress-Archive -Path (Join-Path $stagingDir "*") -DestinationPath $outputResolved -Force
Remove-Item -LiteralPath $stagingDir -Recurse -Force

Write-Host "Created release bundle: $outputResolved" -ForegroundColor Green
