// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {PriceConverter} from "src/PriceConverter.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {FundMe} from "src/FundMe.sol";

contract TestFundMe is Test {
    /**
     * To be able to set a custom deployer account, we cant use vm.broadcast.
     * In other words, we can't use the deploy script.
     * I'm not sure if we are supposed to use deploy scripts in unit tests or only on integrations tests anyway.
     */
    FundMe fundMe;

    address DEPLOYER = makeAddr("DEPLOYER");
    address USER = makeAddr("USER");

    uint256 STARTING_BALANCE = 10 ether;
    uint256 FUND_VALUE = 1 ether;

    modifier userFunded() {
        vm.prank(USER);
        fundMe.fund{value: FUND_VALUE}();
        _;
    }

    function setUp() external {
        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.activeNetworkConfig();

        vm.prank(DEPLOYER);
        fundMe = new FundMe(priceFeed);

        vm.deal(DEPLOYER, STARTING_BALANCE);
        vm.deal(USER, STARTING_BALANCE);
    }

    /** FUNCTIONS */
    function testFundAddsFunderToArray() external {
        // Arrange
        address expectedAddress = USER;
        address actualAddress;

        // Act
        vm.prank(USER);
        fundMe.fund{value: FUND_VALUE}();
        actualAddress = fundMe.getFunder(0);

        // Assert
        assertEq(expectedAddress, actualAddress);
    }

    function testFundAddsAmountFundedToMapping() external {
        // Arrange
        uint256 expectedAmount = FUND_VALUE;
        uint256 actualAmount;

        // Act
        vm.prank(USER);
        fundMe.fund{value: expectedAmount}();
        actualAmount = fundMe.getAmountFunded(USER);

        // Assert
        assertEq(expectedAmount, actualAmount);
    }

    function testReceiveCallsFund() external {
        vm.prank(USER);
        (bool success,) = address(fundMe).call{value: FUND_VALUE}("");

        assert(success);
        assertEq(USER, fundMe.getFunder(0));
        assertEq(FUND_VALUE, fundMe.getAmountFunded(USER));
    }


    function testFallbackCallsFund() external {
        vm.prank(USER);
        // Theres no function with this selector, so fallback is triggered
        (bool success,) = address(fundMe).call{value: FUND_VALUE}("0x12345678");

        assert(success);
        assertEq(USER, fundMe.getFunder(0));
        assertEq(FUND_VALUE, fundMe.getAmountFunded(USER));
    }

    /** EVENTS */
    function testFundEmitsEvent() external {
        vm.prank(USER);
        vm.expectEmit(true, true, false, false);
        emit FundMe.FundMe__ContractFunded(USER, FUND_VALUE);
        fundMe.fund{value: FUND_VALUE}();
    }

    function testWithdrawEmitsEvent() external userFunded {
        vm.prank(DEPLOYER);
        vm.expectEmit(true, false, false, false);
        emit FundMe.FundMe__ContractWithdrawn(address(fundMe).balance);
        fundMe.withdraw();
    }

    /** ERRORS */
    function testFundRevertsWithErrorIfNotEnoughUsd() external {
        vm.prank(USER);
        vm.expectRevert(FundMe.FundMe__NotEnoughUsd.selector);
        fundMe.fund();
    }

    function testWithdrawRevertsWithErrorIfNotOwner() external userFunded {
        vm.prank(USER);
        vm.expectRevert(FundMe.FundMe__NotOwner.selector);
        fundMe.withdraw();
    }
}
