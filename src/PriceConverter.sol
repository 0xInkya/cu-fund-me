// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(address priceFeed) public view returns (uint256) {
        (, int256 answer,,,) = AggregatorV3Interface(priceFeed).latestRoundData();
        return uint256(answer * 1e10); // Returns asset price in correct format
    }

    function getConversion(uint256 amount, address priceFeed) public view returns (uint256) {
        uint256 unitPrice = getPrice(priceFeed);
        uint256 totalPrice = (unitPrice * amount) / 1e18;
        return totalPrice;
    }
}
