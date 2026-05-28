# PixelGuard Hook

PixelGuard is a Uniswap v4 Hook built for the OKX Build X Hackathon Hook track on X Layer.

For a one-page judge overview, see `JUDGES.md`.

Every swap through a PixelGuard pool does two visible things:

1. `beforeSwap` classifies the trade. Large exact-input swaps receive a higher dynamic LP fee override and emit a `GuardedSwap` event.
2. `afterSwap` mints a fully on-chain 24x24 SVG PixelGuard receipt NFT to the trader and increments a per-pool guard reserve counter.

The one-line pitch:

> Every swap leaves a pixel. Risky exits fund the guard.

## Why This Fits The Hackathon

The official Hook track requires a Uniswap v4 Hook project deployed on X Layer with a V4 Pool and verifiable contract addresses. PixelGuard is designed to score on:

- **Innovation:** combines viral swap receipts with Hook-native risk classification and dynamic fee overrides.
- **Market value:** gives meme and launch pools a visible protection primitive without building a full launchpad.
- **Completion:** real swaps trigger `beforeSwap` and `afterSwap`, and tests prove the behavior end to end.

Official references:

- Hackathon page: https://web3.okx.com/zh-hans/xlayer/build-x-hackathon/hook
- X Layer network info: https://web3.okx.com/sv/xlayer/docs/developer/build-on-xlayer/network-information
- X Layer Foundry verification: https://web3.okx.com/ja/xlayer/docs/developer/verify-a-smart-contract/verify-with-foundry

## Contracts

- `src/PixelGuardHook.sol`
  - Hook permissions: `beforeSwap`, `afterSwap`
  - ERC-721 receipt NFT APIs: `balanceOf`, `ownerOf`, `tokenURI`
  - ERC-721 transfer APIs: `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`
  - Pool stats: `beforeSwapCount`, `afterSwapCount`, `guardReserve`, `lastFeeOverride`
  - Trader stats: `traderRiskScore`, `receiptOfTraderByIndex`

## Core Parameters

- Standard fee override: `3000` = 0.30%
- Guarded fee override: `10000` = 1.00%
- Large swap threshold: `5 ether` token units
- Base guard reserve increment: `10`
- Large swap risk score: `75`

The pool uses `LPFeeLibrary.DYNAMIC_FEE_FLAG`, so the Hook's returned fee override is meaningful for swaps.

## Local Setup

Install Foundry, then run:

```powershell
git submodule update --init --recursive
forge test
forge build
```

This repo was verified with Foundry `1.7.1`.

## Test Evidence

Current test suite:

- Swap mints a PixelGuard receipt to the trader.
- PixelGuard receipts support approval and transfer flows.
- `tokenURI` returns on-chain JSON and embedded SVG image data.
- `afterSwap` accrues guard reserve units.
- Large swaps record risk and return the guarded fee override.
- Template utility tests still pass.

Run:

```powershell
forge test
```

Expected current result:

```text
17 tests passed, 0 failed, 0 skipped
```

## X Layer Deployment

Chinese quickstart: `docs/submission/final-quickstart-zh.md`.

X Layer network details from OKX docs:

| Network | RPC | Chain ID | Explorer |
|---|---|---:|---|
| X Layer mainnet | `https://rpc.xlayer.tech` or `https://xlayerrpc.okx.com` | `196` | `https://www.okx.com/web3/explorer/xlayer` |
| X Layer testnet | `https://testrpc.xlayer.tech/terigon` or `https://xlayertestrpc.okx.com/terigon` | `1952` | `https://www.okx.com/web3/explorer/xlayer-test` |

Uniswap's deployment docs list X Layer mainnet v4 addresses:

- PoolManager: `0x360e68faccca8ca495c1b759fd9eee466db9fb32`
- PositionManager: `0xcf1eafc6928dc385a342e7c6491d371d2871458b`
- Universal Router: `0xda00ae15d3a71466517129255255db7c0c0956d3`
- Permit2: `0x000000000022D473030F116dDEE9F6B43aC78BA3`

This repo's demo swap script uses Hookmate's simple `IUniswapV4Router04` interface, not the official Universal Router interface. Deploy the Hookmate router once and set `V4_SWAP_ROUTER`.

The scripts support explicit environment variables:

- `V4_POOL_MANAGER`
- `V4_POSITION_MANAGER`
- `V4_SWAP_ROUTER`
- `HOOK_ADDRESS`
- `TOKEN0`
- `TOKEN1`

Mainnet is the recommended path because Uniswap publishes X Layer mainnet v4 addresses. Testnet is also supported, but only if you provide the current X Layer testnet `V4_POOL_MANAGER`, `V4_POSITION_MANAGER`, and a compatible swap router address.

To run the same PowerShell workflow on testnet, append `-Network testnet` to each runbook command after filling those testnet v4 addresses.

Create `.env` from `.env.example`, then deploy:

```powershell
$env:PATH="$env:USERPROFILE\.foundry\bin;$env:PATH"
```

Check `.env` before deployment:

```powershell
.\tools\pixelguard-env-check.ps1
```

After deployment, check that configured addresses have code on the selected X Layer network:

```powershell
.\tools\pixelguard-chain-check.ps1
```

To inspect the deployment wallet address and balances without printing the private key:

```powershell
.\tools\pixelguard-wallet-check.ps1
```

For the least error-prone path, use the guided PowerShell runbook:

```powershell
.\tools\pixelguard-deploy.ps1 -Step test
.\tools\pixelguard-deploy.ps1 -Step demoTokens
.\tools\pixelguard-deploy.ps1 -Step router
.\tools\pixelguard-deploy.ps1 -Step hook
.\tools\pixelguard-deploy.ps1 -Step pool
.\tools\pixelguard-deploy.ps1 -Step swap
.\tools\pixelguard-deploy.ps1 -Step largeSwap
.\tools\pixelguard-deploy.ps1 -Step read
```

Copy printed values into `docs/submission/deployment-results.md` after every step. The deploy scripts print the Hook address, PoolId, router, tokens, and swap amount so you do not have to dig through broadcast JSON during the final hour.

After filling `docs/submission/deployment-results.md`, generate the final copy/paste pack for Google Form and X:

```powershell
.\tools\pixelguard-submit-pack.ps1
```

The generated pack includes the short/technical descriptions, full deployment evidence, contract fields, X post copy, demo voiceover, and screen checklist.

You can also check whether the submission fields are complete:

```powershell
.\tools\pixelguard-readiness.ps1
```

After broadcasting deployment transactions, summarize Foundry broadcast JSON:

```powershell
.\tools\pixelguard-broadcast-summary.ps1
.\tools\pixelguard-broadcast-summary.ps1 -UpdateResults
.\tools\pixelguard-generate-explorer-links.ps1
```

Or run the post-deployment finalizer:

```powershell
.\tools\pixelguard-finalize-submission.ps1
```

For a full local audit of everything that does not require wallet credentials:

```powershell
.\tools\pixelguard-local-audit.ps1
```

To create a source/docs release bundle:

```powershell
.\tools\pixelguard-make-release-zip.ps1
.\tools\pixelguard-verify-release-zip.ps1
```

Recommended path: use **X Layer mainnet** because Uniswap's public v4 deployment list includes X Layer mainnet addresses. If you do not already have two ERC20 addresses for the demo pool, deploy demo tokens first and copy the printed `Recommended TOKEN0` and `Recommended TOKEN1` addresses into `.env`:

```powershell
forge script script/00_DeployDemoTokens.s.sol `
  --rpc-url $env:XLAYER_MAINNET_RPC `
  --private-key $env:PRIVATE_KEY `
  --broadcast
```

Deploy a Hookmate demo router if `V4_SWAP_ROUTER` is empty:

```powershell
forge script script/00_DeployHookmateRouter.s.sol `
  --rpc-url $env:XLAYER_MAINNET_RPC `
  --private-key $env:PRIVATE_KEY `
  --broadcast
```

Copy the printed router address into `V4_SWAP_ROUTER`.

Deploy the Hook:

```powershell
$env:PATH="$env:USERPROFILE\.foundry\bin;$env:PATH"

forge script script/00_DeployHook.s.sol `
  --rpc-url $env:XLAYER_MAINNET_RPC `
  --private-key $env:PRIVATE_KEY `
  --broadcast
```

Copy the deployed Hook address into `HOOK_ADDRESS`, then create the pool and add liquidity:

```powershell
forge script script/01_CreatePoolAndAddLiquidity.s.sol `
  --rpc-url $env:XLAYER_MAINNET_RPC `
  --private-key $env:PRIVATE_KEY `
  --broadcast
```

Run a demo swap:

```powershell
forge script script/03_Swap.s.sol `
  --rpc-url $env:XLAYER_MAINNET_RPC `
  --private-key $env:PRIVATE_KEY `
  --broadcast
```

Read the Hook state:

```powershell
forge script script/04_ReadPixelGuard.s.sol `
  --rpc-url $env:XLAYER_MAINNET_RPC
```

For the Demo video, run a normal swap and a large swap. The swap receiver and PixelGuard receipt owner are both the deployment wallet. The large swap uses `SWAP_AMOUNT=5e18` in the PowerShell runbook and should emit `GuardedSwap`.

## Verify On OKX Explorer

OKX docs recommend applying for an OKLink API key, waiting one to two minutes after deployment, then using Foundry verification with an OKLink verify URL.

Example for X Layer testnet:

```powershell
forge verify-contract `
  --rpc-url $env:XLAYER_TESTNET_RPC `
  --verifier-url "https://www.oklink.com/api/v5/explorer/contract/verify-source-code-plugin/XLAYER_TESTNET" `
  --verifier-api-key $env:OKLINK_API_KEY `
  --constructor-args $(cast abi-encode "constructor(address)" $env:V4_POOL_MANAGER) `
  --watch `
  $env:HOOK_ADDRESS `
  src/PixelGuardHook.sol:PixelGuardHook
```

For mainnet, use `XLAYER` in the verify URL.

## Submission Package

See:

- `docs/submission/demo-video-script.md`
- `docs/submission/completion-audit.md`
- `docs/submission/final-30-minute-runbook.md`
- `docs/submission/中文最终冲刺.md`
- `docs/submission/final-quickstart-zh.md`
- `docs/submission/google-form-answers.md`
- `docs/submission/twitter-plan.md`
- `docs/submission/x-account-kit.md`
- `docs/submission/submission-checklist.md`
- `docs/submission/deployment-results.md`
- `docs/submission/generated-submit-pack.md` after running `tools/pixelguard-submit-pack.ps1`

## Important Notes

- X account creation and posting are intentionally left to the project owner.
- Wallet funding, private-key handling, and final deployment broadcasting require the project owner's wallet.
- Do not submit until the deployed Hook address, Pool address, verified source, demo video URL, and X account post are all in the checklist.

