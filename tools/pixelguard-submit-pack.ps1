param(
    [string]$ResultsPath = "docs/submission/deployment-results.md",
    [string]$OutputPath = "docs/submission/generated-submit-pack.md"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Test-Path $ResultsPath)) {
    throw "Missing results file: $ResultsPath"
}

function Read-Results {
    param([string]$Path)

    $values = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line.StartsWith("- ")) {
            $content = $line.Substring(2)
            $parts = $content.Split(":", 2)
            if ($parts.Length -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim()
                if ([string]::IsNullOrWhiteSpace($value)) {
                    $value = "[FILL]"
                }
                $values[$key] = $value
            }
        }
    }

    return $values
}

function Value-OrFill {
    param(
        [hashtable]$Values,
        [string]$Key
    )

    if ($Values.ContainsKey($Key)) {
        return $Values[$Key]
    }

    return "[FILL]"
}

$v = Read-Results $ResultsPath

$network = Value-OrFill $v "Network"
$chainId = Value-OrFill $v "Chain ID"
$hook = Value-OrFill $v "PixelGuard Hook"
$poolId = Value-OrFill $v "V4 PoolId"
$hookUrl = Value-OrFill $v "OKX Explorer Hook URL"
$poolUrl = Value-OrFill $v "OKX Explorer pool/swap URL"
$repo = Value-OrFill $v "GitHub repository URL"
$demo = Value-OrFill $v "Demo video URL"
$xAccount = Value-OrFill $v "X account"
$normalSwap = Value-OrFill $v "Demo swap tx"
$largeSwap = Value-OrFill $v "Guarded large swap tx"
$verification = Value-OrFill $v "Hook verification URL"
$rpc = Value-OrFill $v "RPC used"
$explorer = Value-OrFill $v "Explorer"
$demoTokenA = Value-OrFill $v "Demo token A"
$demoTokenB = Value-OrFill $v "Demo token B"
$router = Value-OrFill $v "Hookmate demo router"
$poolManager = Value-OrFill $v "V4 PoolManager"
$positionManager = Value-OrFill $v "V4 PositionManager"
$currency0 = Value-OrFill $v "Currency0"
$currency1 = Value-OrFill $v "Currency1"
$tickLower = Value-OrFill $v "Tick lower"
$tickUpper = Value-OrFill $v "Tick upper"
$demoTokenDeployTx = Value-OrFill $v "Demo token deploy tx"
$routerDeployTx = Value-OrFill $v "Hookmate router deploy tx"
$hookDeployTx = Value-OrFill $v "Hook deploy tx"
$poolTx = Value-OrFill $v "Pool initialize/add-liquidity tx"
$receiptTokenId = Value-OrFill $v "Latest receipt tokenId"
$receiptOwner = Value-OrFill $v "Latest receipt owner"
$receiptTokenUri = Value-OrFill $v "Latest receipt tokenURI captured"
$xPost = Value-OrFill $v "X submission post URL"

$content = @"
# PixelGuard Generated Submit Pack

Generated from $ResultsPath.

## Google Form Short Description

PixelGuard is a Uniswap v4 Hook on X Layer that turns every swap into an on-chain 24x24 SVG receipt NFT while using beforeSwap to classify risky large swaps and return a guarded dynamic LP fee override. afterSwap mints the receipt and updates a per-pool guard reserve counter, making Hook behavior visible, shareable, and verifiable through real swaps.

## Google Form Technical Description

PixelGuard enables beforeSwap and afterSwap permissions. beforeSwap records the pool swap index, decodes the trader from hookData, classifies large exact-input swaps, stores traderRiskScore, emits GuardedSwap, and returns a dynamic fee override for dynamic-fee pools. afterSwap mints an ERC-721 PixelGuard receipt NFT to the trader, stores receipt metadata including an on-chain seed, emits PixelReceiptMinted, and increments guardReserve. The submitted pool uses a dynamic-fee Uniswap v4 pool on $network (chain id $chainId). The project includes Foundry tests proving real v4 swap-triggered minting, tokenURI/SVG generation, reserve accounting, large-swap risk behavior, and receipt transfer/approval behavior.

## Submission Facts

- Project name: PixelGuard Hook
- One-line pitch: Every swap leaves a pixel. Risky exits fund the guard.
- Network: $network
- Chain ID: $chainId
- Hook: $hook
- Hook verification: $verification
- PoolId: $poolId
- Normal swap tx: $normalSwap
- Guarded large swap tx: $largeSwap
- OKX Hook URL: $hookUrl
- OKX pool/swap URL: $poolUrl
- Repository: $repo
- Demo video: $demo
- X account: $xAccount

## Google Form Contract Fields

Use these if the form asks for addresses, links, or transactions separately.

- Network: $network
- Chain ID: $chainId
- RPC used: $rpc
- Explorer: $explorer
- Demo token A: $demoTokenA
- Demo token B: $demoTokenB
- Hookmate demo router: $router
- PixelGuard Hook: $hook
- V4 PoolManager: $poolManager
- V4 PositionManager: $positionManager
- V4 PoolId: $poolId
- Currency0: $currency0
- Currency1: $currency1
- Tick lower: $tickLower
- Tick upper: $tickUpper
- Demo token deploy tx: $demoTokenDeployTx
- Hookmate router deploy tx: $routerDeployTx
- Hook deploy tx: $hookDeployTx
- Pool initialize/add-liquidity tx: $poolTx
- Normal swap tx: $normalSwap
- Guarded large swap tx: $largeSwap
- Hook verification URL: $verification
- OKX Explorer Hook URL: $hookUrl
- OKX Explorer pool/swap URL: $poolUrl
- Latest receipt tokenId: $receiptTokenId
- Latest receipt owner: $receiptOwner
- Latest receipt tokenURI captured: $receiptTokenUri
- GitHub repository: $repo
- Demo video: $demo
- X account: $xAccount
- X submission post: $xPost

## Deployment Evidence Narrative

PixelGuard was deployed on $network (chain id $chainId). The submitted Hook contract is $hook and the submitted v4 PoolId is $poolId. The pool uses PoolManager $poolManager, PositionManager $positionManager, Currency0 $currency0, and Currency1 $currency1. A normal swap transaction ($normalSwap) demonstrates that beforeSwap and afterSwap are reachable through a real v4 swap. A guarded large swap transaction ($largeSwap) demonstrates the large-swap risk path and guarded fee override. The latest receipt evidence is tokenId $receiptTokenId owned by $receiptOwner with tokenURI captured as $receiptTokenUri.

## Final X Submission Post

PixelGuard Hook submitted to Hook the Future.

Every swap leaves a pixel. Risky exits fund the guard.

Uniswap v4 Hook on X Layer:
- beforeSwap classifies large swaps and returns a guarded dynamic fee override
- afterSwap mints a 24x24 on-chain SVG receipt NFT
- guardReserve updates after real swaps

Hook: $hook
PoolId: $poolId
Repo: $repo
Demo: $demo
Tx: $largeSwap

@XLayerOfficial @Uniswap @flapdotsh

## Demo Voiceover Short Version

PixelGuard is a Uniswap v4 Hook deployed on $network. A normal swap triggers beforeSwap and afterSwap; the trader receives an on-chain SVG receipt and the guard reserve increases. A larger swap triggers a guarded risk score and higher dynamic fee override. The Hook address, PoolId, swap transactions, and receipt metadata are all verifiable on-chain.

## Demo Screen Checklist

- Local audit: show 20 tests passing.
- Hook explorer page: $hookUrl
- Pool/swap explorer page: $poolUrl
- Normal swap tx: $normalSwap
- Guarded large swap tx: $largeSwap
- Latest receipt owner: $receiptOwner
- Latest receipt tokenURI: $receiptTokenUri

## Final Human Checklist

- [ ] Replace every `[FILL]` above.
- [ ] Confirm Hook source is verified.
- [ ] Confirm normal swap tx and guarded large swap tx are visible on OKX Explorer.
- [ ] Confirm X post includes `@XLayerOfficial @Uniswap @flapdotsh`.
- [ ] Confirm Google Form is submitted before 2026-05-28 23:59 UTC.
"@

New-Item -ItemType Directory -Force (Split-Path -Parent $OutputPath) | Out-Null
Set-Content -Path $OutputPath -Value $content -Encoding utf8
Write-Host "Generated $OutputPath" -ForegroundColor Green

