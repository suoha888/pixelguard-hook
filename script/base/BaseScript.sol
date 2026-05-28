// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

import {IUniswapV4Router04} from "hookmate/interfaces/router/IUniswapV4Router04.sol";
import {AddressConstants} from "hookmate/constants/AddressConstants.sol";

import {Deployers} from "test/utils/Deployers.sol";

/// @notice Shared configuration between scripts
contract BaseScript is Script, Deployers {
    address immutable deployerAddress;

    /////////////////////////////////////
    // --- Configure These ---
    /////////////////////////////////////
    IERC20 internal token0;
    IERC20 internal token1;
    IHooks internal hookContract;
    /////////////////////////////////////

    Currency immutable currency0;
    Currency immutable currency1;

    constructor() {
        token0 = IERC20(vm.envOr("TOKEN0", address(0x0165878A594ca255338adfa4d48449f69242Eb8F)));
        token1 = IERC20(vm.envOr("TOKEN1", address(0xa513E6E4b8f2a923D98304ec87F64353C4D5C853)));
        hookContract = IHooks(vm.envOr("HOOK_ADDRESS", address(0)));

        // Make sure artifacts are available, either deploy or configure.
        deployArtifacts();

        deployerAddress = getDeployer();

        (currency0, currency1) = getCurrencies();

        vm.label(address(permit2), "Permit2");
        vm.label(address(poolManager), "V4PoolManager");
        vm.label(address(positionManager), "V4PositionManager");
        vm.label(address(swapRouter), "V4SwapRouter");

        vm.label(address(token0), "Currency0");
        vm.label(address(token1), "Currency1");

        vm.label(address(hookContract), "HookContract");
    }

    function _etch(address target, bytes memory bytecode) internal override {
        if (block.chainid == 31337) {
            vm.rpc("anvil_setCode", string.concat('["', vm.toString(target), '",', '"', vm.toString(bytecode), '"]'));
        } else {
            revert("Unsupported etch on this network");
        }
    }

    function deployPoolManager() internal override {
        address configured = vm.envOr("V4_POOL_MANAGER", address(0));
        if (configured != address(0)) {
            poolManager = IPoolManager(configured);
        } else if (block.chainid == 196) {
            poolManager = IPoolManager(0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32);
        } else if (block.chainid == 31337) {
            super.deployPoolManager();
        } else {
            revert("Set V4_POOL_MANAGER for this network");
        }
    }

    function deployPositionManager() internal override {
        address configured = vm.envOr("V4_POSITION_MANAGER", address(0));
        if (configured != address(0)) {
            positionManager = IPositionManager(configured);
        } else if (block.chainid == 196) {
            positionManager = IPositionManager(0xcF1EAFC6928dC385A342E7C6491d371d2871458b);
        } else if (block.chainid == 31337) {
            super.deployPositionManager();
        } else {
            revert("Set V4_POSITION_MANAGER for this network");
        }
    }

    function deployRouter() internal override {
        address configured = vm.envOr("V4_SWAP_ROUTER", address(0));
        if (configured != address(0)) {
            swapRouter = IUniswapV4Router04(payable(configured));
        } else if (block.chainid == 31337) {
            super.deployRouter();
        } else {
            swapRouter = IUniswapV4Router04(payable(address(0)));
        }
    }

    function getCurrencies() internal view returns (Currency, Currency) {
        require(address(token0) != address(token1));

        if (token0 < token1) {
            return (Currency.wrap(address(token0)), Currency.wrap(address(token1)));
        } else {
            return (Currency.wrap(address(token1)), Currency.wrap(address(token0)));
        }
    }

    function getDeployer() internal returns (address) {
        address[] memory wallets = vm.getWallets();

        if (wallets.length > 0) {
            return wallets[0];
        } else {
            return msg.sender;
        }
    }
}
