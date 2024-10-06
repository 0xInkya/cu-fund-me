// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {Constants} from "script/HelperConfig.s.sol";
import {FundMe} from "src/FundMe.sol";

contract FundFundMe is Script, Constants {
    function fundFundMe(address funder, address mostRecentlyDeployed) public {
        vm.startBroadcast(funder);
        FundMe(payable(mostRecentlyDeployed)).fund{value: FUND_VALUE}();
        vm.stopBroadcast();
        console2.log("Funded FundMe with %s", FUND_VALUE);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(msg.sender, mostRecentlyDeployed);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address owner, address mostRecentlyDeployed) public {
        uint256 balance = mostRecentlyDeployed.balance;
        vm.startBroadcast(owner);
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        console2.log("Withdrawn %s from FundMe", balance);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(msg.sender, mostRecentlyDeployed);
    }
}
