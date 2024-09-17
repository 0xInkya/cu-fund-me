// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {HelperConfig, Constants} from "script/HelperConfig.s.sol";
import {PriceConverter} from "src/PriceConverter.sol";
import {FundMe} from "src/FundMe.sol";

contract TestFundMe is Test, Constants {
    /**
     * To be able to set a custom deployer account, we cant use vm.broadcast.
     * In other words, we can't use the deploy script.
     * I'm not sure if we are supposed to use deploy scripts in unit tests or only on integrations tests anyway.
     */
    error TestFundMe__CallUnsuccessful();

    FundMe fundMe;

    address OWNER = makeAddr("owner");
    address FUNDER = makeAddr("funder");

    modifier userFunded() {
        vm.prank(FUNDER);
        fundMe.fund{value: FUND_VALUE}();
        _;
    }

    function setUp() external {
        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.getConfig().priceFeed;

        vm.prank(OWNER);
        fundMe = new FundMe(priceFeed);

        vm.deal(OWNER, STARTING_BALANCE);
        vm.deal(FUNDER, STARTING_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                                  FUND
    //////////////////////////////////////////////////////////////*/
    function testFundRevertsWithErrorIfNotEnoughUsd() external {
        vm.prank(FUNDER);
        vm.expectRevert(FundMe.FundMe__NotEnoughUsd.selector);
        fundMe.fund();
    }

    function testFundAddsFunderToArray() external {
        // Arrange / Act
        vm.prank(FUNDER);
        fundMe.fund{value: FUND_VALUE}();

        // Assert
        assertEq(FUNDER, fundMe.getFunder(0));
    }

    function testFundAddsAmountFundedToMapping() external {
        // Arrange / Act
        vm.prank(FUNDER);
        fundMe.fund{value: FUND_VALUE}();

        // Assert
        assertEq(FUND_VALUE, fundMe.getAmountFunded(FUNDER));
    }

    function testFundEmitsEvent() external {
        vm.expectEmit(true, true, false, false);
        emit FundMe.FundMe__ContractFunded(FUNDER, FUND_VALUE);
        vm.prank(FUNDER);
        fundMe.fund{value: FUND_VALUE}();
    }

    function testReceiveCallsFund() external {
        vm.expectEmit(true, true, false, false);
        emit FundMe.FundMe__ContractFunded(FUNDER, FUND_VALUE);
        vm.prank(FUNDER);
        (bool success,) = address(fundMe).call{value: FUND_VALUE}("");
        if (!success) revert TestFundMe__CallUnsuccessful();
    }

    function testFallbackCallsFund() external {
        vm.expectEmit(true, true, false, false);
        emit FundMe.FundMe__ContractFunded(FUNDER, FUND_VALUE);
        vm.prank(FUNDER);
        (bool success,) = address(fundMe).call{value: FUND_VALUE}("0x12345678"); // Theres no function with this selector, so fallback is triggered
        if (!success) revert TestFundMe__CallUnsuccessful();
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/
    function testWithdrawRevertsWithErrorIfNotOwner() external userFunded {
        vm.expectRevert(FundMe.FundMe__NotOwner.selector);
        vm.prank(FUNDER);
        fundMe.withdraw();
    }

    function testWithdrawResetsFundersArray() external userFunded {
        // Arrange / Act
        vm.prank(OWNER);
        fundMe.withdraw();

        // Assert
        vm.expectRevert();
        fundMe.getFunder(0);
    }

    function testWithdrawResetsFunderToAmountFundedMapping() external userFunded {
        // Arrange / Act
        vm.prank(OWNER);
        fundMe.withdraw();

        // Assert
        assertEq(fundMe.getAmountFunded(FUNDER), 0);
    }

    function testWithdrawPaysOwner() external userFunded {
        // Arrange
        uint256 balanceAfterUserFunded = address(fundMe).balance;
        uint256 ownerBalanceBeforeWithdrawing = OWNER.balance;

        // Act
        vm.prank(OWNER);
        fundMe.withdraw();

        // Assert
        uint256 ownerBalanceAfterWithdrawing = OWNER.balance;
        assert((balanceAfterUserFunded + ownerBalanceBeforeWithdrawing) == ownerBalanceAfterWithdrawing);
    }

    function testWithdrawEmitsEvent() external userFunded {
        vm.expectEmit(true, false, false, false);
        emit FundMe.FundMe__ContractWithdrawn(address(fundMe).balance);
        vm.prank(OWNER);
        fundMe.withdraw();
    }
}
