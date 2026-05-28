# PixelGuard Hook Judge Brief

PixelGuard is a yield-generating Uniswap v4 Hook for X Layer that turns transaction receipts into yield-bearing utility collectibles while providing dynamic LP protection.

## One-Line Pitch

Every swap leaves a pixel. Risky exits fund the guard.

## Hook Callbacks

| Callback | Purpose | Evidence |
|---|---|---|
| `beforeSwap` | Checks trader's NFT holdings for fee discounts (0.20% normal / 0.80% guarded). Classifies large swaps (>= 5 tokens) and dynamic fee overrides (1.00% LP fee + 0.50% Hook Fee taken to treasury). Returns `BeforeSwapDelta` to settle the hook fee. | `src/PixelGuardHook.sol`, `testUtilityFeeDiscount`, `testGuardedHookFeeCollection` |
| `afterSwap` | Mints an on-chain SVG ERC-721 receipt, stores receipt metadata, increments `guardReserve`, updates staking accumulator (`rewardPerShare` and `claimDebt`), and calls `poolManager.take()` to withdraw the hook fee. | `src/PixelGuardHook.sol`, `testSwapMintsPixelReceiptToTrader`, `testRewardClaimingAccumulator` |

## Why It Fits The Track

- **Innovation**: First hook to combine dynamic LP protection with custom hook-fee treasury yield, pro-rata claim accumulators, and transaction-encoded NFT utility discounts.
- **Market Value**: Gives meme and token launch pools a retention loop where trading activity directly pays dividends to early collectors and encourages holding receipts for fee discounts.
- **Completion**: Fully written smart contract, comprehensive unit tests, deployment runbooks on X Layer mainnet, OKLink explorer verification, and a premium dApp page.

## Local Verification

```powershell
.\tools\pixelguard-local-audit.ps1
```

Expected result:

```text
PixelGuard local audit passed.
20 tests passed, 0 failed, 0 skipped
```

GitHub Actions is configured in `.github/workflows/test.yml` to run Foundry build and tests on push, pull request, and manual dispatch.

## X Layer Deployment Path

Recommended quickstart:

```text
docs/submission/final-quickstart-zh.md
```

Full runbook:

```text
docs/submission/final-30-minute-runbook.md
```

Post-deployment finalizer:

```powershell
.\tools\pixelguard-finalize-submission.ps1
```

Live chain sanity check:

```powershell
.\tools\pixelguard-chain-check.ps1
```

Wallet balance check:

```powershell
.\tools\pixelguard-wallet-check.ps1
```

## Submission Evidence

After deployment, the important evidence is collected in:

```text
docs/submission/deployment-results.md
docs/submission/generated-submit-pack.md
```

The final generated pack includes:

- Hook address and verification URL.
- V4 PoolId.
- normal swap transaction.
- guarded large swap transaction.
- latest receipt tokenId, owner, and tokenURI.
- OKLink explorer URLs.
- Google Form text.
- X post copy.
- demo screen checklist.

## Release Bundle

The release zip is:

```text
dist/PixelGuard-Hook-submission.zip
```

It is generated and checked by:

```powershell
.\tools\pixelguard-make-release-zip.ps1
.\tools\pixelguard-verify-release-zip.ps1
```

The verifier rejects `.env`, `cache/`, `out/`, `broadcast/`, `dist/`, `node_modules/`, `lib/`, and private-key-looking content.

## Prototype Scope

PixelGuard is a hackathon prototype. The guarded fee and reserve counter are demonstrable Hook-native primitives, not a claim of guaranteed protection, refunds, or yield.

