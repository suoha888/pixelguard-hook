# PixelGuard Hook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a deployable Uniswap v4 PixelGuard Hook for the OKX Build X Hackathon with tests, scripts, and submission materials.

**Architecture:** Replace the template Counter Hook with `PixelGuardHook`, a focused Hook plus ERC-721 receipt contract that uses `beforeSwap` for risk classification and `afterSwap` for receipt minting and guard reserve accounting. Keep deployment scripts close to the v4-template structure so X Layer deployment remains familiar.

**Tech Stack:** Solidity 0.8.26+, Foundry, Uniswap v4 core/periphery template, OpenZeppelin Uniswap Hooks, X Layer EVM.

---

### Task 1: Project Setup

**Files:**
- Modify: `README.md`
- Add: `.env.example`

- [ ] Install Foundry if `forge` is missing.
- [ ] Initialize git state from the cloned v4 template.
- [ ] Install git submodules with `git submodule update --init --recursive`.
- [ ] Run the template tests once to establish the baseline.

### Task 2: Write PixelGuard Tests First

**Files:**
- Delete: `test/Counter.t.sol`
- Add: `test/PixelGuardHook.t.sol`

- [ ] Write a failing test that verifies a swap mints a receipt NFT to the trader.
- [ ] Write a failing test that verifies `tokenURI` returns on-chain JSON/SVG metadata.
- [ ] Write a failing test that verifies guard reserve increases after a swap.
- [ ] Write a failing test that verifies a large exact-input swap emits and records a higher risk score.
- [ ] Run the tests and confirm they fail because `PixelGuardHook` does not exist yet.

### Task 3: Implement PixelGuard Hook

**Files:**
- Delete: `src/Counter.sol`
- Add: `src/PixelGuardHook.sol`

- [ ] Implement Hook permissions for `beforeSwap` and `afterSwap`.
- [ ] Implement minimal ERC-721 receipt ownership and metadata.
- [ ] Implement per-pool stats, trader receipt lookup, risk score, and guard reserve accounting.
- [ ] Generate deterministic 24x24 SVG from a stored seed.
- [ ] Run tests until all PixelGuard tests pass.

### Task 4: Update Deployment And Demo Scripts

**Files:**
- Modify: `script/00_DeployHook.s.sol`
- Modify: `script/01_CreatePoolAndAddLiquidity.s.sol`
- Modify: `script/03_Swap.s.sol`
- Add: `script/04_ReadPixelGuard.s.sol`

- [ ] Replace Counter references with PixelGuardHook.
- [ ] Keep Hook salt mining flags aligned with `beforeSwap` and `afterSwap`.
- [ ] Add a read script that prints receipt, reserve, and stats after demo swaps.
- [ ] Run `forge build` to confirm scripts compile.

### Task 5: Submission Materials

**Files:**
- Modify: `README.md`
- Add: `docs/submission/demo-video-script.md`
- Add: `docs/submission/twitter-plan.md`
- Add: `docs/submission/submission-checklist.md`

- [ ] Document project pitch, callbacks, deployment commands, and verification commands.
- [ ] Write a 1-3 minute demo video script.
- [ ] Write an X/Twitter posting plan tagging @XLayerOfficial, @Uniswap, and @flapdotsh.
- [ ] Write a final checklist covering Pool address, Hook address, verified source, demo video, X account, and Google Form.

### Task 6: Final Verification

**Files:**
- All changed files.

- [ ] Run `forge test`.
- [ ] Run `forge build`.
- [ ] Confirm there are no stale Counter references.
- [ ] Confirm docs match the implemented contract names and commands.
- [ ] Report any remaining external steps that require the user's wallet, X account, API key, or private deployment key.
