// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {Constants} from "script/HelperConfig.s.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "script/Interactions.s.sol";
import {FundMe} from "src/FundMe.sol";

contract InteractionsTest is Test, Constants {
    DeployFundMe deployer;
    FundMe fundMe;
    FundFundMe fundFundMe;
    WithdrawFundMe withdrawFundMe;

    address FUNDER = makeAddr("funder");

    /**
     * We cant pass an argument (like a deployer address) to the deploy script run function
     * So whenever we want to act as the deployer we need to call fundMe.getOwner()
     *
     * I also changed the interactions scripts to take in an address to pass to the broadcast function
     */
    function setUp() external {
        deployer = new DeployFundMe();
        fundMe = deployer.run();

        vm.deal(FUNDER, STARTING_BALANCE);
        fundFundMe = new FundFundMe();
        withdrawFundMe = new WithdrawFundMe();
    }

    /*//////////////////////////////////////////////////////////////
                              FUND FUND ME
    //////////////////////////////////////////////////////////////*/
    function testFundFundMe() external {
        // Arrange / Act
        fundFundMe.fundFundMe(FUNDER, address(fundMe));

        // Assert
        assertEq(fundMe.getAmountFunded(FUNDER), FUND_VALUE);
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAW FUND ME
    //////////////////////////////////////////////////////////////*/
    function testWithdrawFundMe() external {
        // Arrange
        uint256 ownerBalance = fundMe.getOwner().balance;
        fundFundMe.fundFundMe(FUNDER, address(fundMe));
        uint256 fundMeBalance = address(fundMe).balance;

        // Act
        withdrawFundMe.withdrawFundMe(fundMe.getOwner(), address(fundMe));

        // Assert
        assertEq(fundMeBalance + ownerBalance, fundMe.getOwner().balance);
    }
}
