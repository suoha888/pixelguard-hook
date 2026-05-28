// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2, Script} from "forge-std/Script.sol";

import {AddressConstants} from "hookmate/constants/AddressConstants.sol";
import {V4RouterDeployer} from "hookmate/artifacts/V4Router.sol";

contract DeployHookmateRouterScript is Script {
    function run() external {
        address poolManager = vm.envOr("V4_POOL_MANAGER", _defaultPoolManager());
        address permit2 = AddressConstants.getPermit2Address();

        vm.startBroadcast();
        address router = V4RouterDeployer.deploy(poolManager, permit2);
        vm.stopBroadcast();

        console2.log("V4_SWAP_ROUTER:", router);
    }

    function _defaultPoolManager() internal view returns (address) {
        if (block.chainid == 196) {
            return 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32;
        }

        address configured = vm.envOr("V4_POOL_MANAGER", address(0));
        require(configured != address(0), "Set V4_POOL_MANAGER");
        return configured;
    }
}
