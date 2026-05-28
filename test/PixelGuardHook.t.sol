// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {EasyPosm} from "./utils/libraries/EasyPosm.sol";

import {PixelGuardHook} from "../src/PixelGuardHook.sol";
import {BaseTest} from "./utils/BaseTest.sol";

contract PixelGuardHookTest is BaseTest {
    using EasyPosm for IPositionManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    event GuardedSwap(
        PoolId indexed poolId, address indexed trader, uint256 indexed swapIndex, uint256 amount, uint16 riskScore
    );
    event PixelReceiptMinted(
        PoolId indexed poolId, address indexed trader, uint256 indexed tokenId, uint256 swapIndex, uint16 guardScore
    );

    Currency currency0;
    Currency currency1;

    PoolKey poolKey;

    PixelGuardHook hook;
    PoolId poolId;

    address trader = address(0xBEEF);

    function setUp() public {
        deployArtifactsAndLabel();

        (currency0, currency1) = deployCurrencyPair();

        address flags = address(uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG) ^ (0x5047 << 144));
        bytes memory constructorArgs = abi.encode(poolManager);
        deployCodeTo("PixelGuardHook.sol:PixelGuardHook", constructorArgs, flags);
        hook = PixelGuardHook(flags);

        poolKey = PoolKey(currency0, currency1, LPFeeLibrary.DYNAMIC_FEE_FLAG, 60, IHooks(hook));
        poolId = poolKey.toId();
        poolManager.initialize(poolKey, Constants.SQRT_PRICE_1_1);

        int24 tickLower = TickMath.minUsableTick(poolKey.tickSpacing);
        int24 tickUpper = TickMath.maxUsableTick(poolKey.tickSpacing);

        uint128 liquidityAmount = 100e18;
        (uint256 amount0Expected, uint256 amount1Expected) = LiquidityAmounts.getAmountsForLiquidity(
            Constants.SQRT_PRICE_1_1,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            liquidityAmount
        );

        positionManager.mint(
            poolKey,
            tickLower,
            tickUpper,
            liquidityAmount,
            amount0Expected + 1,
            amount1Expected + 1,
            address(this),
            block.timestamp,
            Constants.ZERO_BYTES
        );

        MockERC20(Currency.unwrap(currency0)).transfer(trader, 20e18);
        vm.prank(trader);
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
    }

    function testSwapMintsPixelReceiptToTrader() public {
        assertEq(hook.balanceOf(trader), 0);

        _swapAsTrader(1e18);

        assertEq(hook.balanceOf(trader), 1);
        assertEq(hook.ownerOf(1), trader);
        assertEq(hook.receiptOfTraderByIndex(trader, 0), 1);

        (PoolId receiptPoolId, address receiptTrader, uint48 swapIndex, uint32 blockNumber, uint16 guardScore) =
            hook.receipts(1);
        assertEq(PoolId.unwrap(receiptPoolId), PoolId.unwrap(poolId));
        assertEq(receiptTrader, trader);
        assertEq(swapIndex, 1);
        assertEq(blockNumber, uint32(block.number));
        assertEq(guardScore, 0);
    }

    function testTokenURIReturnsOnchainJsonAndSvg() public {
        _swapAsTrader(1e18);

        string memory uri = hook.tokenURI(1);

        assertTrue(bytes(uri).length > 500);
        assertTrue(_contains(uri, "data:application/json;utf8,"));
        assertTrue(_contains(uri, "PixelGuard #1"));
        assertTrue(_contains(uri, "data:image/svg+xml;base64,"));
    }

    function testAfterSwapAccruesGuardReserve() public {
        assertEq(hook.guardReserve(poolId), 0);

        _swapAsTrader(1e18);

        assertEq(hook.beforeSwapCount(poolId), 1);
        assertEq(hook.afterSwapCount(poolId), 1);
        assertEq(hook.guardReserve(poolId), hook.BASE_GUARD_UNITS());
    }

    function testStandardSwapRecordsStandardRiskAndFeeOverride() public {
        _swapAsTrader(1e18);

        assertEq(hook.traderRiskScore(poolId, trader), hook.STANDARD_RISK_SCORE());
        assertEq(hook.lastFeeOverride(poolId), hook.STANDARD_LP_FEE());
    }

    function testLargeSwapRecordsRiskAndHigherFeeOverride() public {
        uint256 amountIn = 5 ether;

        vm.expectEmit(true, true, true, true, address(hook));
        emit GuardedSwap(poolId, trader, 1, amountIn, hook.LARGE_SWAP_RISK_SCORE());

        _swapAsTrader(amountIn);

        assertEq(hook.traderRiskScore(poolId, trader), hook.LARGE_SWAP_RISK_SCORE());
        assertEq(hook.lastFeeOverride(poolId), hook.GUARDED_LP_FEE());
        assertEq(hook.guardReserve(poolId), hook.BASE_GUARD_UNITS() + hook.LARGE_SWAP_RISK_SCORE());
    }

    function testReceiptSupportsApprovalsAndTransfers() public {
        address collector = address(0xCAFE);

        _swapAsTrader(1e18);

        vm.prank(trader);
        hook.approve(collector, 1);

        assertEq(hook.getApproved(1), collector);

        vm.prank(collector);
        hook.transferFrom(trader, collector, 1);

        assertEq(hook.ownerOf(1), collector);
        assertEq(hook.balanceOf(trader), 0);
        assertEq(hook.balanceOf(collector), 1);
        assertEq(hook.getApproved(1), address(0));
    }

    function testSafeTransferRequiresERC721ReceiverForContracts() public {
        PixelGuardReceiver receiver = new PixelGuardReceiver();
        PixelGuardNonReceiver nonReceiver = new PixelGuardNonReceiver();

        _swapAsTrader(1e18);

        vm.prank(trader);
        vm.expectRevert("PXG: unsafe receiver");
        hook.safeTransferFrom(trader, address(nonReceiver), 1);

        vm.prank(trader);
        hook.safeTransferFrom(trader, address(receiver), 1);

        assertEq(hook.ownerOf(1), address(receiver));
    }

    function testTransferUpdatesReceiptsByTraderList() public {
        address collector = address(0xCAFE);

        _swapAsTrader(1e18);

        assertEq(hook.balanceOf(trader), 1);
        assertEq(hook.getReceiptCountOfTrader(trader), 1);
        assertEq(hook.receiptOfTraderByIndex(trader, 0), 1);
        assertEq(hook.getReceiptCountOfTrader(collector), 0);

        vm.prank(trader);
        hook.transferFrom(trader, collector, 1);

        assertEq(hook.balanceOf(trader), 0);
        assertEq(hook.getReceiptCountOfTrader(trader), 0);

        assertEq(hook.balanceOf(collector), 1);
        assertEq(hook.getReceiptCountOfTrader(collector), 1);
        assertEq(hook.receiptOfTraderByIndex(collector, 0), 1);
    }

    function testOwnerWithdrawal() public {
        vm.deal(address(hook), 1 ether);
        assertEq(address(hook).balance, 1 ether);

        address recipient = address(0xDAB);

        vm.prank(trader);
        vm.expectRevert("PXG: not owner");
        hook.withdrawToken(address(0), recipient, 0.5 ether);

        vm.prank(hook.hookOwner());
        hook.withdrawToken(address(0), recipient, 0.5 ether);
        assertEq(address(hook).balance, 0.5 ether);
        assertEq(recipient.balance, 0.5 ether);

        MockERC20 dummyToken = new MockERC20("Dummy", "DMY", 18);
        dummyToken.mint(address(hook), 1000e18);

        vm.prank(trader);
        vm.expectRevert("PXG: not owner");
        hook.withdrawToken(address(dummyToken), recipient, 500e18);

        vm.prank(hook.hookOwner());
        hook.withdrawToken(address(dummyToken), recipient, 500e18);
        assertEq(dummyToken.balanceOf(address(hook)), 500e18);
        assertEq(dummyToken.balanceOf(recipient), 500e18);
    }

    function testLargeSwapDecimalsAdaptation() public {
        MockERC20 token6 = new MockERC20("6 Decimals", "SIX", 6);
        token6.mint(address(this), 10_000 ether);
        token6.approve(address(permit2), type(uint256).max);
        token6.approve(address(swapRouter), type(uint256).max);
        permit2.approve(address(token6), address(positionManager), type(uint160).max, type(uint48).max);
        permit2.approve(address(token6), address(poolManager), type(uint160).max, type(uint48).max);

        MockERC20 token18 = new MockERC20("18 Decimals", "EIGHTEEN", 18);
        token18.mint(address(this), 10_000 ether);
        token18.approve(address(permit2), type(uint256).max);
        token18.approve(address(swapRouter), type(uint256).max);
        permit2.approve(address(token18), address(positionManager), type(uint160).max, type(uint48).max);
        permit2.approve(address(token18), address(poolManager), type(uint160).max, type(uint48).max);

        Currency curr0 = Currency.wrap(address(token6));
        Currency curr1 = Currency.wrap(address(token18));
        if (address(token18) < address(token6)) {
            curr0 = Currency.wrap(address(token18));
            curr1 = Currency.wrap(address(token6));
        }

        PoolKey memory key6 = PoolKey(curr0, curr1, LPFeeLibrary.DYNAMIC_FEE_FLAG, 60, IHooks(hook));
        PoolId pid6 = key6.toId();
        poolManager.initialize(key6, Constants.SQRT_PRICE_1_1);

        int24 tickLower = TickMath.minUsableTick(key6.tickSpacing);
        int24 tickUpper = TickMath.maxUsableTick(key6.tickSpacing);
        positionManager.mint(
            key6, tickLower, tickUpper, 100e6, 100e18, 100e18, address(this), block.timestamp, Constants.ZERO_BYTES
        );

        token6.transfer(trader, 20e6);
        vm.prank(trader);
        token6.approve(address(swapRouter), type(uint256).max);

        vm.prank(trader);
        swapRouter.swapExactTokensForTokens({
            amountIn: 5e6,
            amountOutMin: 0,
            zeroForOne: address(token6) == Currency.unwrap(curr0),
            poolKey: key6,
            hookData: abi.encode(trader),
            receiver: trader,
            deadline: block.timestamp + 1
        });

        assertEq(hook.traderRiskScore(pid6, trader), hook.LARGE_SWAP_RISK_SCORE());
    }

    function testSupportsErc721AndMetadataInterfaces() public view {
        assertTrue(hook.supportsInterface(0x01ffc9a7));
        assertTrue(hook.supportsInterface(0x80ac58cd));
        assertTrue(hook.supportsInterface(0x5b5e139f));
        assertFalse(hook.supportsInterface(0xffffffff));
    }

    function _swapAsTrader(uint256 amountIn) internal returns (BalanceDelta swapDelta) {
        vm.prank(trader);
        swapDelta = swapRouter.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: 0,
            zeroForOne: true,
            poolKey: poolKey,
            hookData: abi.encode(trader),
            receiver: trader,
            deadline: block.timestamp + 1
        });
    }

    function _contains(string memory value, string memory needle) internal pure returns (bool) {
        bytes memory haystack = bytes(value);
        bytes memory target = bytes(needle);
        if (target.length > haystack.length) return false;

        for (uint256 i = 0; i <= haystack.length - target.length; i++) {
            bool matched = true;
            for (uint256 j = 0; j < target.length; j++) {
                if (haystack[i + j] != target[j]) {
                    matched = false;
                    break;
                }
            }
            if (matched) return true;
        }

        return false;
    }
}

contract PixelGuardReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract PixelGuardNonReceiver {}
