# PixelGuard Hackathon Submission Checklist

Official page: https://web3.okx.com/zh-hans/xlayer/build-x-hackathon/hook

Deadline: 2026-05-28 23:59 UTC.

## Hard Requirements

- [ ] Project is based on Uniswap v4 Hook logic.
- [ ] Hook contract deployed on X Layer mainnet or testnet.
- [ ] V4 Pool deployed/initialized on X Layer mainnet or testnet.
- [ ] Hook behavior triggered by a real swap on X Layer.
- [ ] Hook contract address is verifiable on OKX Explorer.
- [ ] Pool address or PoolId is included in submission.
- [ ] `docs/submission/deployment-results.md` is filled with Hook, PoolId, tx hashes, and links.
- [ ] `tools/pixelguard-submit-pack.ps1` has generated `docs/submission/generated-submit-pack.md`.
- [ ] All `[FILL]` placeholders in `generated-submit-pack.md` are replaced.
- [ ] A normal swap and a guarded large swap have both been executed.
- [ ] Independent project X account exists.
- [ ] Submission X post tags `@XLayerOfficial`, `@Uniswap`, and `@flapdotsh`.
- [ ] Project posted during the hackathon period.
- [ ] Google Form submitted before deadline.

## Recommended Bonus

- [ ] 1-3 minute Demo video recorded.
- [ ] Demo video shows `beforeSwap` behavior.
- [ ] Demo video shows `afterSwap` receipt minting.
- [ ] Demo video shows `receipts(tokenId)` seed or `tokenURI(tokenId)`.
- [ ] Demo video shows OKX Explorer pages.
- [ ] README includes deployment and verification commands.

## Fill Before Submission

- Project name: `PixelGuard Hook`
- One-line pitch: `Every swap leaves a pixel. Risky exits fund the guard.`
- GitHub repo:
- X account:
- X submission post:
- Demo video:
- Hook contract address:
- Hook verification URL:
- V4 Pool address or PoolId:
- Pool initialization tx:
- Demo swap tx:
- Network: `X Layer mainnet`
- Chain ID: `196`

## Google Form Notes

Use this short description:

```text
PixelGuard is a Uniswap v4 Hook on X Layer that turns every swap into an on-chain 24x24 SVG receipt NFT while using beforeSwap to classify risky large swaps and return a guarded dynamic LP fee override. afterSwap mints the receipt and updates a per-pool guard reserve counter, making Hook behavior visible, shareable, and verifiable through real swaps.
```

Use this technical description:

```text
The Hook enables beforeSwap and afterSwap permissions. beforeSwap records the pool swap index, decodes the trader from hookData, classifies large exact-input swaps, stores traderRiskScore, emits GuardedSwap, and returns a dynamic fee override. afterSwap mints a PixelGuard receipt NFT to the trader, stores receipt metadata, emits PixelReceiptMinted, and increments guardReserve. Tests create a v4 dynamic-fee pool, add liquidity, execute swaps through the router, and assert receipt ownership, tokenURI, reserve accounting, and large-swap risk behavior.
```

## Final Sanity Check

Run locally before submitting:

```powershell
forge test
forge build
.\tools\pixelguard-submit-pack.ps1
rg "Counter" src test script README.md .env.example
```

The only acceptable `Counter` result is no result.
