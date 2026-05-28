# PixelGuard X Account Kit

You said you will create and operate the independent X account. These assets and drafts are ready to use.

## Visual Assets

- Avatar: `docs/brand/pixelguard-avatar.svg`
- Banner: `docs/brand/pixelguard-banner.svg`

If X does not accept SVG uploads directly, open the SVG in a browser and export/screenshot it as PNG.

## Profile

```text
Name: PixelGuard Hook
Bio: Every swap leaves a pixel. A Uniswap v4 Hook for viral receipts and guarded meme pools on X Layer.
Website: [GITHUB_REPOSITORY_URL]
```

## Pinned Post

```text
PixelGuard Hook submitted to Hook the Future.

Every swap leaves a pixel. Risky exits fund the guard.

Uniswap v4 Hook on X Layer:
- beforeSwap classifies large swaps and returns a guarded dynamic fee override
- afterSwap mints a 24x24 on-chain SVG receipt NFT
- guardReserve updates after real swaps

Hook: [PIXELGUARD_HOOK]
PoolId: [V4_POOL_ID]
Repo: [GITHUB_REPOSITORY_URL]
Demo: [DEMO_VIDEO_URL]

@XLayerOfficial @Uniswap @flapdotsh
```

## 4-Post Launch Thread

### Post 1

```text
Introducing PixelGuard Hook.

Every swap leaves a pixel.
Risky exits fund the guard.

Built for the @XLayerOfficial x @Uniswap x @flapdotsh Hook the Future hackathon.

PixelGuard uses Uniswap v4 beforeSwap + afterSwap to turn trades into on-chain SVG receipts and pool protection signals.
```

### Post 2

```text
The Hook behavior is simple and verifiable:

beforeSwap:
- counts swaps
- reads trader from hookData
- scores large swaps
- returns a guarded dynamic fee override

afterSwap:
- mints a 24x24 on-chain SVG receipt NFT
- records the receipt seed
- increments guardReserve
```

### Post 3

```text
Why this matters for meme and launch pools:

Communities already trade around moments. PixelGuard makes each swap visible, collectible, and inspectable while giving large exits a Hook-native risk signal.

No separate app needed. The pool itself creates the receipt.
```

### Post 4

```text
Demo links:

Hook: [PIXELGUARD_HOOK]
PoolId: [V4_POOL_ID]
Normal swap: [DEMO_SWAP_TX]
Guarded swap: [GUARDED_LARGE_SWAP_TX]
Repo: [GITHUB_REPOSITORY_URL]
Video: [DEMO_VIDEO_URL]

@XLayerOfficial @Uniswap @flapdotsh
```

## Short Updates During Review

```text
PixelGuard local audit:
17 tests passed
forge build passed
forge fmt --check passed

Next: X Layer deployment proof + demo video.
```

```text
PixelGuard receipt flow:
swap -> beforeSwap score -> afterSwap mint -> on-chain SVG tokenURI

The demo shows the Hook firing through a real v4 swap.
```

```text
Large swap path:
amount >= 5e18 -> GuardedSwap event -> higher dynamic LP fee override -> guardReserve increases after swap.
```

## Tone Guardrails

- Do not say funds are guaranteed safe.
- Do not promise yield.
- Do not imply the prototype is audited.
- Say "guarded signal", "prototype", "demo", and "Hook-native primitive" instead.

