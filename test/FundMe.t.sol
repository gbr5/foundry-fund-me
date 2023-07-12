// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

// Types of testing:
//
// 1. Unit test: Testing a specific part of our code
// 2. Integration: Testing how our code works with other parts of our code
// 3. Forked: Testing our code in a simulated environment
// 4. Staging: Testing our code in a real environment that is not prod (testnet or mainnet)

contract FundMeTest is Test {
    FundMe public fundMe;
    DeployFundMe public fundMeDeployer;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 10e18;
    uint256 constant STARTING_VALUE = 10 ether;
    uint256 constant GAS_PRICE = 1;
    address ownerAddress;
    address fundMeAddress;

    function setUp() external {
        fundMeDeployer = new DeployFundMe();
        fundMe = fundMeDeployer.run();
        vm.deal(USER, STARTING_VALUE);
        ownerAddress = fundMe.getOwner();
        fundMeAddress = address(fundMe);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testMinimumUSDValue() public {
        uint256 minimumUsd = fundMe.MINIMUM_USD();

        console.log("minimumUsd: ", minimumUsd);

        assertEq(minimumUsd, 50e18);
    }

    function testOwnerIsMsgSender() public {
        console.log("owner: ", ownerAddress);
        console.log("msg.sender: ", msg.sender);
        console.log("address(this): ", address(this));

        // When we deploy the FundMe contract inside this contract,
        // this contract is the owner since it deployed the FundMe contract!
        // msg.sender it's actually us
        // Even if we set vm.prank as we see it below, it doesn't change the actual msg.sender
        vm.prank(address(this));

        // But when we deploy the FundMe contract from the deployer
        // msg.sender is the owner

        // assertEq(owner, address(this)); // this works when FundMe contract is deployed from here
        assertEq(ownerAddress, msg.sender); // This works when FundMe contract is deployed from the deployer
    }

    // to run this test with the sepolia network
    // forge test --match-test testPriceFeedVersionIsAccurate --fork-url $SEPOLIA_RPC_URL
    //
    // Important to keep in mind!!
    // Making too many api calls to alchemy might be expensive
    // Make as many tests that don't need to fork as possible
    //
    // But forked testnet tests are hugely important!
    function testPriceFeedVersionIsAcurate() public {
        uint256 version = fundMe.getVersion();

        console.log("version: ", version);

        assertEq(version, 4);
    }

    function testFundFailsWithoutEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        // address funderAddress = fundMe.getFunder(0);
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOffFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    // Pattern to build a test
    // 1. Arrange
    // 2. Act
    // 3. Assert

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = ownerAddress.balance;
        uint256 startingFundMeBalance = fundMeAddress.balance;

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(ownerAddress);
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = ownerAddress.balance;
        uint256 endingFundMeBalance = fundMeAddress.balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // hoax is a cheatcode (look for forge cheatcode hoax)
            // it combines vm.prank and vm.deal
            address iAddr = address(i);
            vm.startPrank(iAddr);
            vm.deal(iAddr, SEND_VALUE);
            vm.stopPrank();
        }

        uint256 startingOwnerBalance = ownerAddress.balance;
        uint256 startingFundMeBalance = fundMeAddress.balance;

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(ownerAddress);
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);
        vm.stopPrank();

        // Assert
        uint256 endingOwnerBalance = ownerAddress.balance;
        uint256 endingFundMeBalance = fundMeAddress.balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testCheaperWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = ownerAddress.balance;
        uint256 startingFundMeBalance = fundMeAddress.balance;

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(ownerAddress);
        fundMe.cheaperWithdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = ownerAddress.balance;
        uint256 endingFundMeBalance = fundMeAddress.balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testCheaperWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // hoax is a cheatcode (look for forge cheatcode hoax)
            // it combines vm.prank and vm.deal
            address iAddr = address(i);
            vm.startPrank(iAddr);
            vm.deal(iAddr, SEND_VALUE);
            vm.stopPrank();
        }

        uint256 startingOwnerBalance = ownerAddress.balance;
        uint256 startingFundMeBalance = fundMeAddress.balance;

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(ownerAddress);
        fundMe.cheaperWithdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);
        vm.stopPrank();

        // Assert
        uint256 endingOwnerBalance = ownerAddress.balance;
        uint256 endingFundMeBalance = fundMeAddress.balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }
}
