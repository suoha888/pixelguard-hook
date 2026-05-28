# PixelGuard Hook Design

## Goal

PixelGuard Hook is a Uniswap v4 Hook project for the OKX Build X Hackathon on X Layer. Every real swap through the hooked pool creates an on-chain 24x24 pixel receipt for the trader and updates a protection reserve. Risky swaps, especially early large sells, trigger a visible guard surcharge through Hook logic.

## Hackathon Fit

- Built around new Uniswap v4 Hook logic.
- Deployable to X Layer mainnet or testnet with a V4 Pool and Hook address.
- Hook behavior is triggered by real swaps.
- Demo can show a swap, a generated pixel receipt, a guard reserve update, and a risk event.
- Social story is simple: "Every swap leaves a pixel. Risky exits fund the guard."

## MVP Scope

PixelGuard v0 includes:

- `beforeSwap`: increments per-pool pre-swap activity and classifies large exact-input swaps as guarded swaps.
- `afterSwap`: mints a deterministic SVG-backed ERC-721 receipt to the trader and accrues a guard reserve counter.
- Read APIs for receipt metadata, pool stats, trader receipt ids, risk score, and guard reserve.
- Foundry tests proving pool creation, liquidity provisioning, swap-triggered minting, reserve accrual, and large swap risk classification.
- Deployment scripts for Hook deployment, pool creation, liquidity, and demo swap.
- Submission docs: demo video script, X/Twitter plan, contract-address checklist, and final Google Form checklist.

## Non-Goals For One-Day Build

- No full launchpad.
- No real Aave rehypothecation.
- No refund escrow in the first version.
- No complex off-chain social oracle.
- No promise of financial insurance. The "guard reserve" is a visible accounting and future utility primitive for the hackathon prototype.

## Hook Behavior

### beforeSwap

The Hook records that a pool is about to swap. If the absolute `amountSpecified` is at or above the configured `largeSwapThreshold`, it marks the transaction as guarded for that pool and sender. This produces an on-chain event and lets the demo show Hook-level pre-trade risk logic.

### afterSwap

The Hook records the actual swap completion. It mints a PixelGuard receipt NFT to the trader. The receipt stores:

- `poolId`
- `trader`
- `swapIndex`
- `guardScore`
- `seed`
- `blockNumber`

The SVG is generated fully on-chain from the stored seed. The same callback also increases the per-pool guard reserve by a deterministic score-derived amount.

Receipts expose standard ERC-721 ownership, approval, and transfer methods so wallets and explorers can reason about them as NFTs rather than opaque Hook state.

## Product Narrative

PixelGuard combines the strongest parts of previous Hook patterns:

- uPEG-style viral visual receipt after every swap.
- SafeSwap-style visible risk classification before a risky swap.
- Flaunch-style fee/reserve flywheel narrative, simplified to avoid overbuilding.

The differentiator is that the NFT is not decorative only. It is a transaction-native receipt proving that a wallet participated in a protected X Layer v4 pool.

## Evidence Of Completion

- `forge test` passes.
- `PixelGuardHook` compiles and exposes correct Hook permissions.
- Tests prove `beforeSwap` and `afterSwap` are triggered by a real v4 swap.
- Tests prove receipt ownership, `tokenURI`, guard reserve, and large swap risk event behavior.
- Scripts compile for deployment on X Layer.
- README and submission docs explain how to deploy, verify, demo, and submit.
