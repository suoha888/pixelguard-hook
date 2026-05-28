// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {console2} from "forge-std/console2.sol";

import {BaseScript} from "./base/BaseScript.sol";

contract SwapScript is BaseScript {
    using PoolIdLibrary for PoolKey;

    function run() external {
        require(address(swapRouter) != address(0), "Set V4_SWAP_ROUTER");

        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: hookContract // This must match the pool
        });
        bytes memory hookData = abi.encode(deployerAddress);
        uint256 amountIn = vm.envOr("SWAP_AMOUNT", uint256(1e18));
        PoolId poolId = poolKey.toId();

        vm.startBroadcast();

        // We'll approve both, just for testing.
        token1.approve(address(swapRouter), type(uint256).max);
        token0.approve(address(swapRouter), type(uint256).max);

        // Execute swap
        swapRouter.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: 0, // Very bad, but we want to allow for unlimited price impact
            zeroForOne: true,
            poolKey: poolKey,
            hookData: hookData,
            receiver: deployerAddress,
            deadline: block.timestamp + 30
        });

        vm.stopBroadcast();

        console2.log("PixelGuard swap complete");
        console2.log("Trader:", deployerAddress);
        console2.log("Hook:", address(hookContract));
        console2.log("Router:", address(swapRouter));
        console2.log("Amount in:", amountIn);
        console2.log("PoolId:");
        console2.logBytes32(PoolId.unwrap(poolId));
    }
}
