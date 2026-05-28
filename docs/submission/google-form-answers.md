# PixelGuard Google Form Answers

Use this as the copy/paste source after deployment. Replace bracketed fields with values from `docs/submission/deployment-results.md`.

## Project Name

```text
PixelGuard Hook
```

## Short Description

```text
PixelGuard is a Uniswap v4 Hook on X Layer that turns every swap into an on-chain 24x24 SVG receipt NFT while using beforeSwap to classify risky large swaps and return a guarded dynamic LP fee override. afterSwap mints the receipt, updates a per-pool guard reserve counter, and accumulates treasury yield via a staking accumulator (rewardPerShare). NFT holders can claim pro-rata dividends from guarded swap fees and enjoy discounted LP fees (0.20% normal / 0.80% guarded) on future swaps, making Hook behavior visible, shareable, and verifiable through real swaps.
```

## Technical Description

```text
PixelGuard enables beforeSwap and afterSwap permissions. beforeSwap records the pool swap index, decodes the trader from hookData, classifies large exact-input swaps, checks NFT holdings for fee discounts (0.20% normal / 0.80% guarded), stores traderRiskScore, emits GuardedSwap, and returns a dynamic fee override with a 0.50% hook fee via BeforeSwapDelta for dynamic-fee pools. afterSwap mints an ERC-721 PixelGuard receipt NFT to the trader, stores receipt metadata including an on-chain seed, updates a staking accumulator (rewardPerShare and claimDebt) for pro-rata treasury yield distribution, calls poolManager.take() to withdraw hook fees into the contract treasury, emits PixelReceiptMinted, and increments guardReserve. NFT holders can call claim() to withdraw accrued yield dividends. The submitted pool uses a dynamic-fee Uniswap v4 pool on X Layer mainnet (chain id 196). The project includes Foundry tests proving real v4 swap-triggered minting, tokenURI/SVG generation, reserve accounting, large-swap risk behavior, NFT fee discounts, hook fee collection, reward claiming, and receipt transfer/approval flows.
```

## One-Line Pitch

```text
Every swap leaves a pixel. Risky exits fund the guard.
```

## Innovation

```text
PixelGuard combines dynamic LP protection with custom hook-fee yield accumulation and transaction-encoded NFT discounts. A normal swap mints a fully on-chain SVG receipt NFT. Large swaps trigger beforeSwap classification, raising the LP fee (1.00%) and taking a 0.50% Hook Fee to the contract treasury. Receipt holders can claim their pro-rata yield share from the treasury, and holding an NFT discounts future swap fees (0.20% normal / 0.80% large).
```

## Market Value

```text
Meme and launch pools need visible proof of activity, user-retainable receipts, and simple protection signals that do not require a full launchpad. PixelGuard can become a lightweight add-on for creator pools: every trade becomes collectible distribution, while risky exits create an observable guard score and reserve counter that communities can monitor.
```

## Completion Evidence

```text
The repository includes the Hook contract, Foundry tests, X Layer deployment scripts, pool creation scripts, swap trigger scripts, an on-chain state reader, OKLink verification command, demo video script, submission checklist, and generated copy/paste submission pack. Local audit passes with 20 tests, forge build, forge fmt --check, PowerShell syntax checks, and submission pack generation.
```

## Network

```text
X Layer mainnet, chain id 196
```

## Contract And Transaction Fields

```text
Hook contract: [PIXELGUARD_HOOK]
Hook verification URL: [HOOK_VERIFICATION_URL]
V4 PoolId: [V4_POOL_ID]
PoolManager: 0x360e68faccca8ca495c1b759fd9eee466db9fb32
PositionManager: 0xcf1eafc6928dc385a342e7c6491d371d2871458b
Normal swap tx: [DEMO_SWAP_TX]
Guarded large swap tx: [GUARDED_LARGE_SWAP_TX]
OKX Explorer Hook URL: [OKX_EXPLORER_HOOK_URL]
OKX Explorer pool/swap URL: [OKX_EXPLORER_POOL_OR_SWAP_URL]
```

## Repository, Demo, Social

```text
GitHub repository: [GITHUB_REPOSITORY_URL]
Demo video: [DEMO_VIDEO_URL]
X account: [X_ACCOUNT]
X submission post: [X_SUBMISSION_POST_URL]
```

## Safety Note

```text
PixelGuard is a hackathon prototype. The guarded fee, reserve counter, treasury yield accumulator, and NFT fee discount are visible Hook-native primitives for demonstration, not a guarantee of price protection, refunds, or yield.
```

