# PixelGuard Hook Judge Brief

PixelGuard is a Uniswap v4 Hook for X Layer that makes swaps visible and collectible while adding a simple guarded fee signal for large exits.

## One-Line Pitch

Every swap leaves a pixel. Risky exits fund the guard.

## Hook Callbacks

| Callback | Purpose | Evidence |
|---|---|---|
| `beforeSwap` | Counts swaps, decodes trader from `hookData`, scores large swaps, emits `GuardedSwap`, returns dynamic LP fee override. | `src/PixelGuardHook.sol`, `testLargeSwapRecordsRiskAndHigherFeeOverride` |
| `afterSwap` | Mints an on-chain SVG ERC-721 receipt, stores receipt metadata, increments `guardReserve`, emits `PixelReceiptMinted`. | `src/PixelGuardHook.sol`, `testSwapMintsPixelReceiptToTrader` |

## Why It Fits The Track

- Innovation: combines viral on-chain swap receipts with Hook-native risk classification and dynamic fee overrides.
- Market value: designed for meme and launch pools that need visible activity, user-retainable receipts, and simple community-readable protection signals.
- Completion: includes Hook contract, Foundry tests, X Layer deployment scripts, demo token/router scripts, state reader, verification command, submission pack, demo script, and release bundle tooling.

## Local Verification

```powershell
.\tools\pixelguard-local-audit.ps1
```

Expected result:

```text
PixelGuard local audit passed.
17 tests passed, 0 failed, 0 skipped
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

