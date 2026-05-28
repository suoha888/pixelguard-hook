# PixelGuard Final Runbook

Use this when you are ready to deploy, verify, record, and submit. The official deadline is **2026-05-28 23:59 UTC**, which is **2026-05-29 07:59 Asia/Shanghai**.

## 0. Preflight

Run these before touching your wallet:

```powershell
.\tools\pixelguard-local-audit.ps1
.\tools\pixelguard-deploy.ps1 -Step test
.\tools\pixelguard-deploy.ps1 -Step build
```

Expected local result:

```text
17 tests passed, 0 failed, 0 skipped
```

## 1. Fill .env

Copy `.env.example` to `.env`, then fill:

```powershell
Copy-Item .env.example .env
notepad .env
```

Required before deployment:

- `PRIVATE_KEY`: deployment wallet private key.
- `OKLINK_API_KEY`: needed for source verification.
- `XLAYER_MAINNET_RPC`: keep `https://rpc.xlayer.tech` unless you have a better RPC.
- `V4_POOL_MANAGER`: keep the default X Layer mainnet address.
- `V4_POSITION_MANAGER`: keep the default X Layer mainnet address.

Leave these empty until the scripts print them:

- `TOKEN0`
- `TOKEN1`
- `V4_SWAP_ROUTER`
- `HOOK_ADDRESS`

After editing `.env`, run:

```powershell
.\tools\pixelguard-env-check.ps1
.\tools\pixelguard-wallet-check.ps1
```

Use X Layer mainnet unless gas or funding blocks you. Mainnet has published Uniswap v4 infrastructure addresses, which reduces final-hour integration risk.

## 2. Deploy Demo Tokens

```powershell
.\tools\pixelguard-deploy.ps1 -Step demoTokens
```

Copy these printed values into `.env`:

- `Recommended TOKEN0`
- `Recommended TOKEN1`

Copy the token addresses and transaction hash into `docs/submission/deployment-results.md`.

## 3. Deploy Demo Swap Router

```powershell
.\tools\pixelguard-deploy.ps1 -Step router
```

Copy the printed router address into:

```text
V4_SWAP_ROUTER=
```

Also copy it into `docs/submission/deployment-results.md`.

## 4. Deploy PixelGuard Hook

```powershell
.\tools\pixelguard-deploy.ps1 -Step hook
```

Copy the printed Hook address into:

```text
HOOK_ADDRESS=
```

Also copy the Hook address and transaction hash into `docs/submission/deployment-results.md`.

## 5. Create V4 Pool And Add Liquidity

```powershell
.\tools\pixelguard-deploy.ps1 -Step pool
```

Copy into `docs/submission/deployment-results.md`:

- `PoolId`
- `Currency0`
- `Currency1`
- tick lower / tick upper
- pool initialize and liquidity transaction hash

## 6. Trigger Real Hook Behavior

Run a normal swap:

```powershell
.\tools\pixelguard-deploy.ps1 -Step swap
```

Run a guarded large swap:

```powershell
.\tools\pixelguard-deploy.ps1 -Step largeSwap
```

Record both transaction hashes. The large swap should cross the `5 ether` threshold and trigger the guarded risk path.

## 7. Read On-Chain Evidence

```powershell
.\tools\pixelguard-deploy.ps1 -Step read
```

Copy into `docs/submission/deployment-results.md`:

- `beforeSwapCount`
- `afterSwapCount`
- `guardReserve`
- latest token id
- latest owner
- latest trader
- guard score
- `tokenURI`

Open the static viewer and paste the `tokenURI` if you want to show the generated SVG in the demo:

```powershell
Invoke-Item docs\demo\receipt-viewer.html
```

You can summarize Foundry broadcast files after the deployment steps:

```powershell
.\tools\pixelguard-broadcast-summary.ps1
```

To prefill any deployment-result fields that can be inferred from broadcast JSON:

```powershell
.\tools\pixelguard-broadcast-summary.ps1 -UpdateResults
```

Review `docs/submission/deployment-results.md` manually afterwards. PoolId, receipt metadata, explorer URLs, repo, video, and X fields still need explicit confirmation.

After Hook and swap transaction fields are filled, generate explorer links:

```powershell
.\tools\pixelguard-generate-explorer-links.ps1
```

After `.env` contains `TOKEN0`, `TOKEN1`, `V4_SWAP_ROUTER`, and `HOOK_ADDRESS`, check the live chain state:

```powershell
.\tools\pixelguard-chain-check.ps1
```

## 8. Verify The Hook

Wait one or two minutes after deployment, then run:

```powershell
.\tools\pixelguard-deploy.ps1 -Step verify
```

Copy the explorer verification URL into `docs/submission/deployment-results.md`.

## 9. Generate Submission Copy

After every field in `deployment-results.md` is filled:

```powershell
.\tools\pixelguard-submit-pack.ps1
```

Or use the post-deployment finalizer to run broadcast summary, explorer-link generation, submission-pack generation, release bundling, and readiness checks together:

```powershell
.\tools\pixelguard-finalize-submission.ps1
```

Check for missing submission fields:

```powershell
.\tools\pixelguard-readiness.ps1
```

This also checks common formatting mistakes: EVM addresses, transaction hashes, tick range, tokenURI prefix, URL fields, and leftover `[FILL]` placeholders in the generated submit pack.

If the only unfinished items are the independent X account and X post, use:

```powershell
.\tools\pixelguard-readiness.ps1 -AllowSocialPending
```

Open:

```powershell
notepad docs\submission\generated-submit-pack.md
```

Replace any remaining `[FILL]` values before submitting. The generated pack includes the short/technical descriptions, full deployment evidence, contract fields, X post copy, demo voiceover, and screen checklist.

## 10. Record Demo Video

Target length: 1 to 3 minutes.

Recommended recording sequence:

1. Show the repo tests passing.
2. Show the deployed Hook address on OKX Explorer.
3. Show the PoolId and swap transaction.
4. Run or replay the normal swap output.
5. Run or replay the large swap output.
6. Show `read` output proving receipt minting and guard reserve.
7. Paste `tokenURI` into `docs/demo/receipt-viewer.html` and show the on-chain SVG receipt.

Use `docs/submission/demo-video-script.md` as the voiceover.

Use `docs/submission/x-account-kit.md` for the X profile, pinned post, and launch thread. Use the SVG assets in `docs/brand/` for the avatar and banner.

## 11. Final Submission

Before Google Form submission, confirm:

- V4 Pool is deployed on X Layer.
- PixelGuard Hook is deployed on X Layer.
- Hook source is verified or verification URL is included.
- Normal swap transaction exists.
- Guarded large swap transaction exists.
- Latest PixelGuard receipt metadata is recorded.
- Demo video URL is ready.
- GitHub repository URL is ready.
- Independent X account has posted and tagged `@XLayerOfficial`, `@Uniswap`, and `@flapdotsh`.

Then submit through the official Google Form linked on the hackathon page.

Use `docs/submission/google-form-answers.md` and `docs/submission/generated-submit-pack.md` as the copy/paste source.

Optionally create a lightweight release bundle:

```powershell
.\tools\pixelguard-make-release-zip.ps1
```

## Emergency Fallbacks

If verification is slow, submit the Hook address, explorer link, deployment transaction, source repository, and note that verification is pending. A verified contract is strongly preferred, but missing the deadline is worse.

If the large swap fails from insufficient demo token balance, reduce `SWAP_AMOUNT` in the script only as a last-resort change. Prefer deploying fresh demo tokens and using the existing `largeSwap` command first.

If X Layer mainnet funding is blocked, switch to testnet only if you have confirmed testnet v4 `PoolManager`, `PositionManager`, and a compatible router. Otherwise, stay on mainnet.

