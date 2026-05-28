// Vercel Serverless Function: /api/faucet
// Transfers 100 PXG-A and 100 PXG-B from the deployer wallet to the requesting address.
// Requires FAUCET_PRIVATE_KEY to be set in Vercel environment variables.

const { ethers } = require("ethers");

const RPC_URL = "https://rpc.xlayer.tech";
const TOKEN0_ADDRESS = "0x1C5b14cb76AEE77B3c66a4aC56731D67BCe17DFb";
const TOKEN1_ADDRESS = "0xA89C0904233AECCb5f6d8f43738891301222ac02";
const FAUCET_AMOUNT = ethers.parseEther("100"); // 100 tokens each

const ERC20_ABI = [
  "function transfer(address to, uint256 amount) returns (bool)",
  "function balanceOf(address owner) view returns (uint256)"
];

module.exports = async function handler(req, res) {
  // CORS headers for browser requests
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { address } = req.body || {};

  if (!address || !ethers.isAddress(address)) {
    return res.status(400).json({ error: "Invalid or missing wallet address" });
  }

  const privateKey = process.env.FAUCET_PRIVATE_KEY;
  if (!privateKey) {
    return res.status(500).json({ error: "Faucet not configured" });
  }

  try {
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const wallet = new ethers.Wallet(privateKey, provider);
    const token0 = new ethers.Contract(TOKEN0_ADDRESS, ERC20_ABI, wallet);
    const token1 = new ethers.Contract(TOKEN1_ADDRESS, ERC20_ABI, wallet);

    // Transfer TOKEN0 (PXG-A)
    const tx0 = await token0.transfer(address, FAUCET_AMOUNT);
    await tx0.wait();

    // Transfer TOKEN1 (PXG-B)
    const tx1 = await token1.transfer(address, FAUCET_AMOUNT);
    await tx1.wait();

    return res.status(200).json({
      success: true,
      txHash0: tx0.hash,
      txHash1: tx1.hash,
      message: "100 PXG-A and 100 PXG-B sent successfully!"
    });
  } catch (e) {
    console.error("Faucet error:", e);
    return res.status(500).json({ error: e.reason || e.message || "Faucet transfer failed" });
  }
}
