// Layout of Contract:
// version
// imports
// natspec
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "src/PriceConverter.sol";

/**
 * @title FundMe
 * @author Inkya
 * @notice Implementation of the FundMe contract from Cyfrin Updraft from 0, following best practices and improving on the original code by implementing ideas learned in later projects.
 * Functionality:
 * 1. Minimum funding amount set on USD
 * 2. Funders get recorded and mapped to amount funded
 * 3. Only contract deployer can withdraw funds
 * 4. Records are reset when withdrawing
 */
contract FundMe {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error FundMe__NotEnoughUsd();
    error FundMe__NotOwner();
    error FundMe__WithdrawFailed();

    /*//////////////////////////////////////////////////////////////
                               CONTRACTS
    //////////////////////////////////////////////////////////////*/
    using PriceConverter for uint256;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private constant MINIMUM_USD = 5 * 10 ** 18;
    address private immutable i_owner;
    address private immutable i_priceFeed;
    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_funderToAmountFunded;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event FundMe__ContractFunded(address indexed funder, uint256 indexed amountFunded);
    event FundMe__ContractWithdrawn(uint256 indexed amountWithdrawn);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(address priceFeed) {
        i_owner = msg.sender;
        i_priceFeed = priceFeed;
    }

    function fund() public payable {
        /**
         * This:
         * using PriceConverter for uint256;
         * msg.value.getConversionRate(i_priceFeed);
         *
         * Is the same as this:
         * PriceConverter.getConversionRate(i_priceFeed, msg.value);
         */
        if (msg.value.getConversion(i_priceFeed) < MINIMUM_USD) revert FundMe__NotEnoughUsd();
        s_funders.push(msg.sender);
        s_funderToAmountFunded[msg.sender] = msg.value;
        emit FundMe__ContractFunded(msg.sender, msg.value);
    }

    function withdraw() public payable onlyOwner {
        uint256 amountWithdrawn = address(this).balance;

        /* Resetting array and mapping */
        uint256 fundersLength = s_funders.length; // Temporary variable to iterate from memory instead of storage, which is more gas efficient
        for (uint256 i = 0; i < fundersLength; i++) {
            s_funderToAmountFunded[s_funders[i]] = 0;
        }
        s_funders = new address[](0); // (0) specifies the initial length of the array

        /* Withdrawing funds from contract */
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool success,) = i_owner.call{value: address(this).balance}("");
        if (!success) revert FundMe__WithdrawFailed();

        emit FundMe__ContractWithdrawn(amountWithdrawn);
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAmountFunded(address funder) public view returns (uint256) {
        return s_funderToAmountFunded[funder];
    }
}
