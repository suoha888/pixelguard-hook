# PixelGuard 1-3 Minute Demo Video Script

## Target Length

90-150 seconds.

## Shot 1: Hook Thesis (0:00-0:15)

Narration:

> PixelGuard is a Uniswap v4 Hook on X Layer. Every swap leaves a pixel receipt, and risky exits fund the guard.

Show:

- Project README title.
- `src/PixelGuardHook.sol`.
- Highlight `beforeSwap` and `afterSwap`.

## Shot 2: Product Mechanism (0:15-0:40)

Narration:

> In `beforeSwap`, the Hook classifies trade risk. Normal trades get the standard fee override. Large swaps trigger a guarded fee and emit a risk event. In `afterSwap`, the Hook mints a fully on-chain 24x24 SVG receipt NFT to the trader and updates the pool's guard reserve.

Show:

- `getHookPermissions()`.
- `_beforeSwap()`.
- `_afterSwap()`.
- `tokenURI()`.

## Shot 3: Tests Prove Real Hook Behavior (0:40-1:05)

Command:

```powershell
forge test
```

Narration:

> These tests create a real v4 pool, add liquidity, execute swaps through the router, and verify that both Hook callbacks fire.

Show test names:

- `testSwapMintsPixelReceiptToTrader`
- `testAfterSwapAccruesGuardReserve`
- `testLargeSwapRecordsRiskAndHigherFeeOverride`
- `testTokenURIReturnsOnchainJsonAndSvg`

## Shot 4: X Layer Deployment Flow (1:05-1:35)

Narration:

> The deployment flow mines the Hook address with the correct v4 permission flags, creates a dynamic-fee pool, adds liquidity, performs a demo swap, and reads the PixelGuard state back on-chain.

Show:

```powershell
forge script script/00_DeployHook.s.sol --rpc-url $env:XLAYER_TESTNET_RPC --private-key $env:PRIVATE_KEY --broadcast
forge script script/01_CreatePoolAndAddLiquidity.s.sol --rpc-url $env:XLAYER_TESTNET_RPC --private-key $env:PRIVATE_KEY --broadcast
forge script script/03_Swap.s.sol --rpc-url $env:XLAYER_TESTNET_RPC --private-key $env:PRIVATE_KEY --broadcast
forge script script/04_ReadPixelGuard.s.sol --rpc-url $env:XLAYER_TESTNET_RPC
```

Show explorer pages for:

- Hook contract.
- Pool transaction.
- Demo swap transaction.

## Shot 5: The Receipt (1:35-2:10)

Narration:

> After the swap, the trader owns a PixelGuard receipt. The metadata and SVG are generated on-chain from the swap context.

Show:

- `ownerOf(latestTokenId)`.
- `receipts(latestTokenId)` to show the stored seed.
- `tokenURI(latestTokenId)`.
- The SVG if decoded in browser.
- `guardReserve(poolId)` increasing.

## Shot 6: Closing (2:10-2:30)

Narration:

> PixelGuard is a small primitive with a large surface area: swap receipts can become social proof, launch credentials, protection tiers, and community rewards. It turns Uniswap v4 Hook logic into something users can see, share, and verify.

Show:

- Final checklist.
- X post tagging `@XLayerOfficial @Uniswap @flapdotsh`.

## Recording Checklist

- Keep terminal font large.
- Show deployed addresses in the explorer.
- Show the exact transaction that triggers the Hook.
- Keep the video under 3 minutes.
- Upload to YouTube, Loom, X video, or another public URL.
