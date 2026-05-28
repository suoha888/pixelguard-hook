// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {IPoolManager, SwapParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {
    BeforeSwapDelta,
    BeforeSwapDeltaLibrary,
    toBeforeSwapDelta
} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface IERC20Minimal {
    function decimals() external view returns (uint8);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

contract PixelGuardHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using Strings for uint256;

    uint24 public constant STANDARD_LP_FEE = 3000;
    uint24 public constant GUARDED_LP_FEE = 10000;

    uint24 public constant DISCOUNTED_LP_FEE = 2000; // 0.20%
    uint24 public constant DISCOUNTED_GUARDED_LP_FEE = 8000; // 0.80%
    uint24 public constant GUARDED_HOOK_FEE = 50; // 0.50% Hook Fee

    uint16 public constant BASE_GUARD_UNITS = 10;
    uint16 public constant STANDARD_RISK_SCORE = 0;
    uint16 public constant LARGE_SWAP_RISK_SCORE = 75;

    string public constant name = "PixelGuard Receipts";
    string public constant symbol = "PXG";

    struct Receipt {
        PoolId poolId; // 32 bytes (Slot 0)
        address trader; // 20 bytes (Slot 1)
        uint48 swapIndex; // 6 bytes (Slot 1)
        uint32 blockNumber; // 4 bytes (Slot 1)
        uint16 guardScore; // 2 bytes (Slot 1)
    }

    address public hookOwner;

    uint256 public totalSupply;

    mapping(uint256 tokenId => Receipt receipt) public receipts;
    mapping(uint256 tokenId => address owner) private _ownerOf;
    mapping(address owner => uint256 balance) private _balanceOf;
    mapping(uint256 tokenId => address approved) private _tokenApprovals;
    mapping(address owner => mapping(address operator => bool approved)) private _operatorApprovals;
    mapping(address trader => uint256[] tokenIds) private _receiptsByTrader;

    mapping(PoolId poolId => uint256 count) public beforeSwapCount;
    mapping(PoolId poolId => uint256 count) public afterSwapCount;
    mapping(PoolId poolId => uint256 reserveUnits) public guardReserve;
    mapping(PoolId poolId => uint24 fee) public lastFeeOverride;
    mapping(PoolId poolId => mapping(address trader => uint16 score)) public traderRiskScore;

    mapping(PoolId poolId => mapping(Currency currency => uint256)) public rewardPerShare;
    mapping(uint256 tokenId => mapping(Currency currency => uint256)) public claimDebt;

    mapping(PoolId poolId => mapping(address trader => uint256 amount)) public pendingHookFee;
    mapping(PoolId poolId => mapping(address trader => Currency currency)) public pendingHookFeeCurrency;

    event RewardClaimed(uint256 indexed tokenId, address indexed owner, address indexed token, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event GuardedSwap(
        PoolId indexed poolId, address indexed trader, uint256 indexed swapIndex, uint256 amount, uint16 riskScore
    );
    event PixelReceiptMinted(
        PoolId indexed poolId, address indexed trader, uint256 indexed tokenId, uint256 swapIndex, uint16 guardScore
    );

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
        hookOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == hookOwner, "PXG: not owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "PXG: zero address");
        emit OwnershipTransferred(hookOwner, newOwner);
        hookOwner = newOwner;
    }

    function withdrawToken(address token, address to, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            require(IERC20Minimal(token).transfer(to, amount), "PXG: transfer failed");
        }
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: true,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "PXG: zero owner");
        return _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _ownerOf[tokenId];
        require(owner != address(0), "PXG: nonexistent token");
        return owner;
    }

    function receiptOfTraderByIndex(address trader, uint256 index) external view returns (uint256) {
        return _receiptsByTrader[trader][index];
    }

    function getReceiptCountOfTrader(address trader) external view returns (uint256) {
        return _receiptsByTrader[trader].length;
    }

    function _removeTokenFromTrader(address from, uint256 tokenId) internal {
        uint256[] storage tokens = _receiptsByTrader[from];
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[length - 1];
                tokens.pop();
                break;
            }
        }
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        ownerOf(tokenId);
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function approve(address spender, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "PXG: not approved");

        _tokenApprovals[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "PXG: self approval");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "PXG: not approved");
        require(ownerOf(tokenId) == from, "PXG: wrong owner");
        require(to != address(0), "PXG: zero receiver");

        delete _tokenApprovals[tokenId];
        _balanceOf[from]--;
        _balanceOf[to]++;
        _ownerOf[tokenId] = to;

        _removeTokenFromTrader(from, tokenId);
        _receiptsByTrader[to].push(tokenId);

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(msg.sender, from, to, tokenId, ""), "PXG: unsafe receiver");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(msg.sender, from, to, tokenId, data), "PXG: unsafe receiver");
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        Receipt memory receipt = receipts[tokenId];
        require(receipt.trader != address(0), "PXG: nonexistent token");

        bytes32 seed =
            _seed(tokenId, receipt.poolId, receipt.trader, receipt.swapIndex, receipt.guardScore, receipt.blockNumber);
        string memory image = Base64.encode(bytes(_svg(receipt, seed)));
        string memory json = string.concat(
            '{"name":"PixelGuard #',
            tokenId.toString(),
            '","description":"A Uniswap v4 swap receipt generated by PixelGuard Hook on X Layer.","attributes":[',
            '{"trait_type":"Swap Index","value":',
            uint256(receipt.swapIndex).toString(),
            '},{"trait_type":"Guard Score","value":',
            uint256(receipt.guardScore).toString(),
            '},{"trait_type":"Block","value":',
            uint256(receipt.blockNumber).toString(),
            '}],"image":"data:image/svg+xml;base64,',
            image,
            '"}'
        );

        return string.concat("data:application/json;utf8,", json);
    }

    function _beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        PoolId poolId = key.toId();
        (address trader, uint256 tokenId) = _parseHookData(sender, hookData);
        uint256 swapIndex = beforeSwapCount[poolId] + 1;
        uint256 amount = _abs(params.amountSpecified);

        beforeSwapCount[poolId] = swapIndex;

        Currency specifiedCurrency = params.amountSpecified < 0
            ? (params.zeroForOne ? key.currency0 : key.currency1)
            : (params.zeroForOne ? key.currency1 : key.currency0);

        uint8 dec = _getDecimals(specifiedCurrency);
        uint256 threshold = 5 * (10 ** dec);

        uint16 riskScore = amount >= threshold ? LARGE_SWAP_RISK_SCORE : STANDARD_RISK_SCORE;

        bool hasDiscount = (tokenId > 0 && _ownerOf[tokenId] == trader);
        uint24 fee = riskScore == LARGE_SWAP_RISK_SCORE
            ? (hasDiscount ? DISCOUNTED_GUARDED_LP_FEE : GUARDED_LP_FEE)
            : (hasDiscount ? DISCOUNTED_LP_FEE : STANDARD_LP_FEE);

        traderRiskScore[poolId][trader] = riskScore;
        lastFeeOverride[poolId] = fee;

        if (riskScore != STANDARD_RISK_SCORE) {
            emit GuardedSwap(poolId, trader, swapIndex, amount, riskScore);
        }

        uint256 feeAmount = 0;
        if (riskScore == LARGE_SWAP_RISK_SCORE && params.amountSpecified < 0) {
            feeAmount = amount * GUARDED_HOOK_FEE / 10000;
        }

        if (feeAmount > 0) {
            pendingHookFee[poolId][trader] = feeAmount;
            pendingHookFeeCurrency[poolId][trader] = specifiedCurrency;

            uint256 totalShares = afterSwapCount[poolId];
            uint256 shares = totalShares == 0 ? 1 : totalShares;
            rewardPerShare[poolId][specifiedCurrency] += (feeAmount * 1e18) / shares;

            BeforeSwapDelta delta = toBeforeSwapDelta(int128(uint128(feeAmount)), 0);
            return (BaseHook.beforeSwap.selector, delta, fee | LPFeeLibrary.OVERRIDE_FEE_FLAG);
        }

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee | LPFeeLibrary.OVERRIDE_FEE_FLAG);
    }

    function _getDecimals(Currency currency) internal view returns (uint8) {
        if (currency.isAddressZero()) {
            return 18;
        }
        try IERC20Minimal(Currency.unwrap(currency)).decimals() returns (uint8 d) {
            return d;
        } catch {
            return 18;
        }
    }

    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata,
        BalanceDelta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        PoolId poolId = key.toId();
        (address trader,) = _parseHookData(sender, hookData);
        uint256 swapIndex = ++afterSwapCount[poolId];
        uint16 guardScore = traderRiskScore[poolId][trader];

        uint256 tokenId = ++totalSupply;
        receipts[tokenId] = Receipt({
            poolId: poolId,
            trader: trader,
            swapIndex: uint48(swapIndex),
            blockNumber: uint32(block.number),
            guardScore: guardScore
        });

        _ownerOf[tokenId] = trader;
        _balanceOf[trader]++;
        _receiptsByTrader[trader].push(tokenId);

        guardReserve[poolId] += BASE_GUARD_UNITS + uint256(guardScore);

        claimDebt[tokenId][key.currency0] = rewardPerShare[poolId][key.currency0];
        claimDebt[tokenId][key.currency1] = rewardPerShare[poolId][key.currency1];

        uint256 feeAmount = pendingHookFee[poolId][trader];
        if (feeAmount > 0) {
            Currency specifiedCurrency = pendingHookFeeCurrency[poolId][trader];
            poolManager.take(specifiedCurrency, address(this), feeAmount);
            delete pendingHookFee[poolId][trader];
            pendingHookFeeCurrency[poolId][trader] = Currency.wrap(address(0));
        }

        emit Transfer(address(0), trader, tokenId);
        emit PixelReceiptMinted(poolId, trader, tokenId, swapIndex, guardScore);

        return (BaseHook.afterSwap.selector, 0);
    }

    function _parseHookData(address sender, bytes calldata hookData)
        internal
        pure
        returns (address trader, uint256 tokenId)
    {
        if (hookData.length >= 64) {
            (trader, tokenId) = abi.decode(hookData, (address, uint256));
        } else if (hookData.length >= 32) {
            trader = abi.decode(hookData, (address));
            tokenId = 0;
        } else {
            trader = sender;
            tokenId = 0;
        }
    }

    function claim(uint256 tokenId, PoolKey calldata key) external {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "PXG: not owner");

        Receipt memory receipt = receipts[tokenId];
        require(PoolId.unwrap(key.toId()) == PoolId.unwrap(receipt.poolId), "PXG: invalid pool key");

        _claimCurrency(tokenId, owner, receipt.poolId, key.currency0);
        _claimCurrency(tokenId, owner, receipt.poolId, key.currency1);
    }

    function _claimCurrency(uint256 tokenId, address owner, PoolId poolId, Currency currency) internal {
        uint256 currentRewardPerShare = rewardPerShare[poolId][currency];
        uint256 debt = claimDebt[tokenId][currency];
        if (currentRewardPerShare > debt) {
            uint256 pending = ((currentRewardPerShare - debt) * 1) / 1e18;
            claimDebt[tokenId][currency] = currentRewardPerShare;
            if (pending > 0) {
                if (currency.isAddressZero()) {
                    payable(owner).transfer(pending);
                } else {
                    require(
                        IERC20Minimal(Currency.unwrap(currency)).transfer(owner, pending), "PXG: claim transfer failed"
                    );
                }
                emit RewardClaimed(tokenId, owner, Currency.unwrap(currency), pending);
            }
        }
    }

    function _abs(int256 value) internal pure returns (uint256) {
        return value < 0 ? uint256(-value) : uint256(value);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender);
    }

    function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data)
        internal
        returns (bool)
    {
        if (to.code.length == 0) {
            return true;
        }

        try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch {
            return false;
        }
    }

    function _seed(
        uint256 tokenId,
        PoolId poolId,
        address trader,
        uint256 swapIndex,
        uint16 guardScore,
        uint256 blockNumber
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(tokenId, poolId, trader, swapIndex, guardScore, blockNumber));
    }

    function _svg(Receipt memory receipt, bytes32 seed) internal pure returns (string memory) {
        string memory pixels;

        for (uint256 i = 0; i < 16; i++) {
            uint256 x = (i % 4) * 6;
            uint256 y = (i / 4) * 6;
            uint8 hue = uint8(seed[i]) % 6;
            pixels = string.concat(
                pixels,
                '<rect x="',
                x.toString(),
                '" y="',
                y.toString(),
                '" width="6" height="6" fill="',
                _color(hue, receipt.guardScore),
                '"/>'
            );
        }

        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges">',
            '<rect width="24" height="24" fill="#111827"/>',
            pixels,
            '<path d="M3 21h18v2H3z" fill="',
            receipt.guardScore > 0 ? "#f97316" : "#22c55e",
            '"/>',
            "</svg>"
        );
    }

    function _color(uint8 hue, uint16 guardScore) internal pure returns (string memory) {
        if (guardScore > 0) {
            if (hue == 0) return "#f97316";
            if (hue == 1) return "#facc15";
            if (hue == 2) return "#fb7185";
            if (hue == 3) return "#c084fc";
            if (hue == 4) return "#38bdf8";
            return "#f8fafc";
        }

        if (hue == 0) return "#22c55e";
        if (hue == 1) return "#14b8a6";
        if (hue == 2) return "#38bdf8";
        if (hue == 3) return "#a3e635";
        if (hue == 4) return "#f8fafc";
        return "#94a3b8";
    }
}
