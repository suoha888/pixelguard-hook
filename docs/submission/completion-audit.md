# PixelGuard Completion Audit

This audit separates work that is complete in the repository from work that must be completed with the project owner's wallet, X account, and Google Form access.

Official source: https://web3.okx.com/zh-hans/xlayer/build-x-hackathon/hook

## Official Requirements

| Requirement | Current Status | Evidence |
|---|---|---|
| Build around Uniswap v4 Hook logic | Complete locally | `src/PixelGuardHook.sol` inherits `BaseHook` and enables `beforeSwap` plus `afterSwap`. |
| New Hook contract logic during hackathon | Complete locally | PixelGuard replaces the template counter with dynamic fee risk scoring, receipt minting, reserve accounting, and on-chain SVG metadata. |
| Deploy Hook on X Layer mainnet or testnet | Owner action required | Deployment script exists: `tools/pixelguard-deploy.ps1 -Step hook`. Requires funded wallet/private key. |
| Deploy or initialize V4 Pool on X Layer | Owner action required | Pool script exists: `tools/pixelguard-deploy.ps1 -Step pool`. Requires deployed Hook, tokens, and wallet. |
| Hook behavior triggered by real swap | Owner action required | Normal and large-swap scripts exist: `-Step swap` and `-Step largeSwap`. Requires deployed pool. |
| Submit verifiable contract address | Owner action required | Verification script exists: `tools/pixelguard-deploy.ps1 -Step verify`. Requires `OKLINK_API_KEY` and deployed Hook address. |
| Independent X account and tagged post | Owner action required | X plan/copy exists in `docs/submission/twitter-plan.md` and `generated-submit-pack.md`. |
| Google Form before deadline | Owner action required | Submission copy pack exists; final form submission requires owner account/browser. |
| Demo video recommended, 1-3 minutes | Ready for owner recording | Script exists in `docs/submission/demo-video-script.md`; receipt viewer exists in `docs/demo/receipt-viewer.html`. |

## Local Deliverables Completed

- Hook contract: `src/PixelGuardHook.sol`
- Foundry tests: `test/PixelGuardHook.t.sol`
- Demo token deployment: `script/00_DeployDemoTokens.s.sol`
- Hookmate router deployment: `script/00_DeployHookmateRouter.s.sol`
- Hook deployment with mined address flags: `script/00_DeployHook.s.sol`
- Dynamic-fee pool creation and liquidity: `script/01_CreatePoolAndAddLiquidity.s.sol`
- Swap and large-swap trigger: `script/03_Swap.s.sol`
- On-chain state reader: `script/04_ReadPixelGuard.s.sol`
- Guided deployment runner: `tools/pixelguard-deploy.ps1`
- Environment checker: `tools/pixelguard-env-check.ps1`
- Live chain checker: `tools/pixelguard-chain-check.ps1`
- Wallet checker: `tools/pixelguard-wallet-check.ps1`
- Submission copy generator: `tools/pixelguard-submit-pack.ps1`
- Submission readiness checker: `tools/pixelguard-readiness.ps1`
- Local audit runner: `tools/pixelguard-local-audit.ps1`
- Explorer link generator: `tools/pixelguard-generate-explorer-links.ps1`
- Post-deployment finalizer: `tools/pixelguard-finalize-submission.ps1`
- Release zip verifier: `tools/pixelguard-verify-release-zip.ps1`
- Final deployment runbook: `docs/submission/final-30-minute-runbook.md`
- Submission checklist: `docs/submission/submission-checklist.md`
- Deployment results template: `docs/submission/deployment-results.md`
- Twitter plan: `docs/submission/twitter-plan.md`
- Demo video script: `docs/submission/demo-video-script.md`
- Receipt viewer: `docs/demo/receipt-viewer.html`

## Local Verification Gates

Run:

```powershell
.\tools\pixelguard-local-audit.ps1
```

This checks:

- `forge build`
- `forge test`
- `forge fmt --check`
- PowerShell syntax for all scripts under `tools`
- submission pack generation
- stale `Counter` references in submission code paths

After deployment, `tools/pixelguard-readiness.ps1` additionally checks filled submission fields for address/hash/URL shape, tick ordering, receipt tokenURI prefix, and leftover `[FILL]` placeholders in `generated-submit-pack.md`.

Expected test result:

```text
20 tests passed, 0 failed, 0 skipped
```

## Final Owner Actions

1. Fill `.env` from `.env.example`.
2. Fund the deployment wallet on X Layer.
3. Run `demoTokens`, `router`, `hook`, `pool`, `swap`, `largeSwap`, `read`, and `verify`.
4. Fill `docs/submission/deployment-results.md`.
5. Run `tools/pixelguard-readiness.ps1`.
6. Run `tools/pixelguard-submit-pack.ps1`.
7. Record and upload the 1-3 minute demo video.
8. Post from the independent X account and tag `@XLayerOfficial`, `@Uniswap`, and `@flapdotsh`.
9. Submit the official Google Form before **2026-05-28 23:59 UTC**.

## Completion Judgment

As of this repository state, the code, tests, scripts, docs, and submission materials that can be completed without wallet credentials or social accounts are complete and locally auditable.

The full hackathon objective is not yet externally complete until the owner performs the wallet deployment, source verification, X account posting, video upload, and Google Form submission.

