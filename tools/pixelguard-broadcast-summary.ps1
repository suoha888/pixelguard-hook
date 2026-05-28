param(
    [ValidateSet("mainnet", "testnet")]
    [string]$Network = "mainnet",
    [string]$ResultsPath = "docs/submission/deployment-results.md",
    [switch]$UpdateResults
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$chainId = if ($Network -eq "mainnet") { "196" } else { "1952" }
$broadcastRoot = Join-Path (Resolve-Path ".").Path "broadcast"

function Read-BroadcastFile {
    param([System.IO.FileInfo]$File)

    $json = Get-Content -Raw -LiteralPath $File.FullName | ConvertFrom-Json
    $txs = @()
    if ($json.transactions) {
        $txs = @($json.transactions)
    }
    $receipts = @()
    if ($json.receipts) {
        $receipts = @($json.receipts)
    }

    [pscustomobject]@{
        Script       = $File.Directory.Parent.Name
        File         = $File.FullName
        LastWrite    = $File.LastWriteTime
        Transactions = $txs
        Receipts     = $receipts
    }
}

function Get-TxHash {
    param(
        $Tx,
        $Run = $null,
        [int]$Index = -1
    )

    if ($Run -and $Index -ge 0 -and $Run.Receipts -and $Run.Receipts.Count -gt $Index) {
        $receiptHash = $Run.Receipts[$Index].transactionHash
        if ($receiptHash) {
            return $receiptHash
        }
    }

    if ($Tx.hash) {
        return $Tx.hash
    }
    if ($Tx.transactionHash) {
        return $Tx.transactionHash
    }
    return $null
}

function Get-ContractAddress {
    param($Tx)

    if ($Tx.contractAddress) {
        return $Tx.contractAddress
    }
    if ($Tx.additionalContracts -and $Tx.additionalContracts.Count -gt 0) {
        return $Tx.additionalContracts[0].address
    }
    return $null
}

function Update-ResultField {
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

if (-not (Test-Path $broadcastRoot)) {
    Write-Host "No root broadcast directory found yet. Run deployment scripts first." -ForegroundColor Yellow
    return
}

$files = Get-ChildItem -Path $broadcastRoot -Recurse -Filter "run-*.json" |
    Where-Object { $_.FullName -match "\\$chainId\\" -and $_.FullName -notmatch "\\dry-run\\" } |
    Sort-Object LastWriteTime

if ($files.Count -eq 0) {
    Write-Host "No broadcast files found for chain id $chainId. Run deployment scripts first." -ForegroundColor Yellow
    return
}

$runs = @($files | ForEach-Object { Read-BroadcastFile $_ })

Write-Host "PixelGuard broadcast summary for chain id $chainId" -ForegroundColor Cyan
foreach ($run in $runs) {
    Write-Host ""
    Write-Host "$($run.Script) :: $($run.LastWrite)" -ForegroundColor Cyan
    Write-Host $run.File

    for ($i = 0; $i -lt $run.Transactions.Count; $i++) {
        $tx = $run.Transactions[$i]
        $hash = Get-TxHash $tx $run $i
        $contract = Get-ContractAddress $tx
        $name = $tx.contractName
        $type = $tx.transactionType
        $function = $tx.function

        if ($hash) {
            Write-Host "  tx: $hash"
            if ($tx.hash -and $tx.hash -ne $hash) {
                Write-Host "  note: using receipt transactionHash; broadcast tx.hash was $($tx.hash)" -ForegroundColor Yellow
            }
        }
        if ($contract) {
            Write-Host "  contract: $contract $name"
        }
        if ($type -or $function) {
            Write-Host "  type/function: $type $function"
        }
    }
}

if (-not $UpdateResults) {
    return
}

if (-not (Test-Path $ResultsPath)) {
    throw "Missing results file: $ResultsPath"
}

$lines = [System.Collections.Generic.List[string]](Get-Content $ResultsPath)

$demoRun = $runs | Where-Object { $_.Script -eq "00_DeployDemoTokens.s.sol" } | Select-Object -Last 1
if ($demoRun) {
    $demoContracts = @($demoRun.Transactions | ForEach-Object { Get-ContractAddress $_ } | Where-Object { $_ })
    $demoTx = Get-TxHash ($demoRun.Transactions | Select-Object -First 1) $demoRun 0
    if ($demoContracts.Count -ge 1) { $lines = Update-ResultField $lines "Demo token A" $demoContracts[0] }
    if ($demoContracts.Count -ge 2) { $lines = Update-ResultField $lines "Demo token B" $demoContracts[1] }
    $lines = Update-ResultField $lines "Demo token deploy tx" $demoTx
}

$routerRun = $runs | Where-Object { $_.Script -eq "00_DeployHookmateRouter.s.sol" } | Select-Object -Last 1
if ($routerRun) {
    $routerTx = $routerRun.Transactions | Select-Object -First 1
    $lines = Update-ResultField $lines "Hookmate demo router" (Get-ContractAddress $routerTx)
    $lines = Update-ResultField $lines "Hookmate router deploy tx" (Get-TxHash $routerTx $routerRun 0)
}

$hookRun = $runs | Where-Object { $_.Script -eq "00_DeployHook.s.sol" } | Select-Object -Last 1
if ($hookRun) {
    $hookTx = $hookRun.Transactions | Where-Object { $_.contractName -eq "PixelGuardHook" } | Select-Object -First 1
    if (-not $hookTx) {
        $hookTx = $hookRun.Transactions | Select-Object -First 1
    }
    $lines = Update-ResultField $lines "PixelGuard Hook" (Get-ContractAddress $hookTx)
    $hookIndex = [array]::IndexOf(@($hookRun.Transactions), $hookTx)
    $lines = Update-ResultField $lines "Hook deploy tx" (Get-TxHash $hookTx $hookRun $hookIndex)
}

$poolRun = $runs | Where-Object { $_.Script -eq "01_CreatePoolAndAddLiquidity.s.sol" } | Select-Object -Last 1
if ($poolRun) {
    $poolTx = $poolRun.Transactions | Select-Object -Last 1
    $poolIndex = [array]::IndexOf(@($poolRun.Transactions), $poolTx)
    $lines = Update-ResultField $lines "Pool initialize/add-liquidity tx" (Get-TxHash $poolTx $poolRun $poolIndex)
}

$swapRuns = @($runs | Where-Object { $_.Script -eq "03_Swap.s.sol" })
if ($swapRuns.Count -ge 1) {
    $normalRun = $swapRuns | Select-Object -First 1
    $normalTx = $normalRun.Transactions | Select-Object -Last 1
    $normalIndex = [array]::IndexOf(@($normalRun.Transactions), $normalTx)
    $lines = Update-ResultField $lines "Demo swap tx" (Get-TxHash $normalTx $normalRun $normalIndex)
}
if ($swapRuns.Count -ge 2) {
    $largeRun = $swapRuns | Select-Object -Last 1
    $largeTx = $largeRun.Transactions | Select-Object -Last 1
    $largeIndex = [array]::IndexOf(@($largeRun.Transactions), $largeTx)
    $lines = Update-ResultField $lines "Guarded large swap tx" (Get-TxHash $largeTx $largeRun $largeIndex)
}

Set-Content -LiteralPath $ResultsPath -Value $lines -Encoding utf8
Write-Host ""
Write-Host "Updated $ResultsPath with values that could be inferred from broadcast files." -ForegroundColor Green
Write-Host "Still review the file manually, especially PoolId, Currency0/1, receipt metadata, explorer URLs, repo, video, and X fields." -ForegroundColor Yellow
