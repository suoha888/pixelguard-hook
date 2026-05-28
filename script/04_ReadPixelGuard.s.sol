// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";

import {BaseScript} from "./base/BaseScript.sol";
import {PixelGuardHook} from "../src/PixelGuardHook.sol";

contract ReadPixelGuardScript is BaseScript {
    using PoolIdLibrary for PoolKey;

    function run() external view {
        require(address(hookContract) != address(0), "Set HOOK_ADDRESS");

        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(hookContract)
        });
        PoolId poolId = poolKey.toId();
        PixelGuardHook hook = PixelGuardHook(address(hookContract));

        console2.log("PixelGuard Hook:", address(hook));
        console2.log("PoolId:");
        console2.logBytes32(PoolId.unwrap(poolId));
        console2.log("beforeSwapCount:", hook.beforeSwapCount(poolId));
        console2.log("afterSwapCount:", hook.afterSwapCount(poolId));
        console2.log("guardReserve:", hook.guardReserve(poolId));
        console2.log("totalSupply:", hook.totalSupply());

        if (hook.totalSupply() > 0) {
            uint256 latestTokenId = hook.totalSupply();
            (PoolId rPoolId, address trader, uint48 swapIndex, uint32 blockNumber, uint16 guardScore) =
                hook.receipts(latestTokenId);
            bytes32 seed = keccak256(
                abi.encode(latestTokenId, rPoolId, trader, uint256(swapIndex), guardScore, uint256(blockNumber))
            );

            console2.log("latest tokenId:", latestTokenId);
            console2.log("latest owner:", hook.ownerOf(latestTokenId));
            console2.log("latest trader:", trader);
            console2.log("latest swapIndex:", uint256(swapIndex));
            console2.log("latest guardScore:", uint256(guardScore));
            console2.log("latest blockNumber:", uint256(blockNumber));
            console2.log("latest seed:");
            console2.logBytes32(seed);
            console2.log("latest tokenURI:", hook.tokenURI(latestTokenId));
        }
    }
}
