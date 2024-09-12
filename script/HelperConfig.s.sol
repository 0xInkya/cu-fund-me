// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "src/FundMe.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if (block.chainid == 1) activeNetworkConfig = getEthereumMainnetConfig();
        else if (block.chainid == 11155111) activeNetworkConfig = getEthereumSepoliaConfig();
        else activeNetworkConfig = getOrCreateAnvilNetworkConfig();
    }

    function getEthereumMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
    }

    function getEthereumSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
    }

    function getOrCreateAnvilNetworkConfig() public returns (NetworkConfig memory) {
        // Get
        if (activeNetworkConfig.priceFeed != address(0)) return activeNetworkConfig;

        // Create
        MockV3Aggregator mock;
        vm.startBroadcast();
        mock = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();
        return NetworkConfig({priceFeed: address(mock)});
    }
}
