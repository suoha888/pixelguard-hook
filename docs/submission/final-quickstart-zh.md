# PixelGuard 中文最终冲刺

这份文档是 `中文最终冲刺.md` 的 ASCII 文件名版本，方便脚本、压缩包和 GitHub 页面引用。

官方截止时间：**2026-05-28 23:59 UTC**，北京时间是 **2026-05-29 07:59**。

## 最短路径

1. 本地检查：

```powershell
.\tools\pixelguard-local-audit.ps1
```

应看到：

```text
PixelGuard local audit passed.
20 tests passed, 0 failed, 0 skipped
```

2. 创建并填写 `.env`：

```powershell
Copy-Item .env.example .env
notepad .env
.\tools\pixelguard-env-check.ps1
.\tools\pixelguard-wallet-check.ps1
```

至少填写 `PRIVATE_KEY` 和 `OKLINK_API_KEY`。主网默认的 `V4_POOL_MANAGER` / `V4_POSITION_MANAGER` 不要随意修改。

3. 按顺序部署：

```powershell
.\tools\pixelguard-deploy.ps1 -Step demoTokens
.\tools\pixelguard-deploy.ps1 -Step router
.\tools\pixelguard-deploy.ps1 -Step hook
.\tools\pixelguard-deploy.ps1 -Step pool
.\tools\pixelguard-deploy.ps1 -Step swap
.\tools\pixelguard-deploy.ps1 -Step largeSwap
.\tools\pixelguard-deploy.ps1 -Step read
.\tools\pixelguard-deploy.ps1 -Step verify
```

4. 把每一步输出填进：

```text
docs/submission/deployment-results.md
```

5. 自动收尾：

```powershell
.\tools\pixelguard-finalize-submission.ps1
```

6. 链上地址体检：

```powershell
.\tools\pixelguard-chain-check.ps1
```

7. 最终检查：

```powershell
.\tools\pixelguard-readiness.ps1
```

全部绿色之前不要提交。

## 必填证据

- Hook 地址
- Hook 验证链接
- V4 PoolId
- normal swap tx
- guarded large swap tx
- OKLink Hook URL
- OKLink swap URL
- latest receipt tokenId / owner / tokenURI
- GitHub repo URL
- Demo 视频 URL
- X submission post URL

## Demo 视频

建议录 1-3 分钟：

1. 本地测试通过
2. OKLink Hook 页面
3. PoolId 或 swap tx
4. normal swap
5. large swap
6. `read` 输出里的 receipt tokenId、owner、tokenURI
7. 打开 `docs/demo/receipt-viewer.html`，粘贴 tokenURI，展示 SVG receipt

## X 和表单

X 素材：

```text
docs/submission/x-account-kit.md
docs/brand/pixelguard-avatar.svg
docs/brand/pixelguard-banner.svg
```

表单复制：

```text
docs/submission/generated-submit-pack.md
docs/submission/google-form-answers.md
```

必须 tag：

```text
@XLayerOfficial @Uniswap @flapdotsh
```

## 应急

如果验证卡住，先提交 Hook 地址、部署 tx、OKLink 地址页、GitHub repo，并注明 verification pending。

如果 large swap 失败，优先确认 demo token 余额或重新部署 demo tokens，不要临时改合约阈值。
