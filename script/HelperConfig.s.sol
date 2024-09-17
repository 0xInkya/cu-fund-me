// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

abstract contract Constants {
    /* Chain IDs */
    uint256 ANVIL_CHAIN_ID = 31337;
    uint256 SEPOLIA_CHAIN_ID = 11155111;
    uint256 MAINNET_CHAIN_ID = 1;

    /* Magic Numbers */
    uint256 STARTING_BALANCE = 10 ether;
    uint256 FUND_VALUE = 0.01 ether;
}

contract HelperConfig is Script, Constants {
    error HelperConfig__ChainNotFound();

    NetworkConfig public anvilNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) networkConfigs;

    uint8 public DECIMALS = 8;
    int256 public INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaConfig();
        networkConfigs[MAINNET_CHAIN_ID] = getMainnetConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == ANVIL_CHAIN_ID) return getOrCreateAnvilConfig();
        else if (networkConfigs[chainId].priceFeed != address(0)) return networkConfigs[chainId];
        else revert HelperConfig__ChainNotFound();
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        /* Get */
        if (anvilNetworkConfig.priceFeed != address(0)) return anvilNetworkConfig;

        /* Create */
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();
        anvilNetworkConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilNetworkConfig;
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
    }
}
