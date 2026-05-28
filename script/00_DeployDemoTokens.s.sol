// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2, Script} from "forge-std/Script.sol";

contract DemoToken {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address account => uint256 balance) public balanceOf;
    mapping(address owner => mapping(address spender => uint256 amount)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(string memory name_, string memory symbol_, address recipient, uint256 supply) {
        name = name_;
        symbol = symbol_;
        _mint(recipient, supply);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) {
            require(allowed >= amount, "DEMO: allowance");
            allowance[from][msg.sender] = allowed - amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "DEMO: balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}

contract DeployDemoTokensScript is Script {
    function run() external {
        address deployer = msg.sender;
        uint256 supply = vm.envOr("DEMO_TOKEN_SUPPLY", uint256(1_000_000e18));

        vm.startBroadcast();
        DemoToken tokenA = new DemoToken("PixelGuard Demo A", "PXGA", deployer, supply);
        DemoToken tokenB = new DemoToken("PixelGuard Demo B", "PXGB", deployer, supply);
        vm.stopBroadcast();

        console2.log("TOKEN0/TOKEN1 must be sorted by address in BaseScript automatically.");
        console2.log("PXGA:", address(tokenA));
        console2.log("PXGB:", address(tokenB));

        address recommendedToken0 = address(tokenA) < address(tokenB) ? address(tokenA) : address(tokenB);
        address recommendedToken1 = address(tokenA) < address(tokenB) ? address(tokenB) : address(tokenA);
        console2.log("Recommended TOKEN0:", recommendedToken0);
        console2.log("Recommended TOKEN1:", recommendedToken1);
    }
}
