// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { Factory } from "../contracts/core/Factory.sol";
import { Router } from "../contracts/core/Router.sol";
import { LendingPoolCore } from "../contracts/core/CoreLogic.sol";
import { LendTokens } from "../contracts/core/LendTokens.sol";
import { Token1 } from "../contracts/Tokens_ERC20/Token1.sol";
import { Token2 } from "../contracts/Tokens_ERC20/Token2.sol";
import { PriceFeedToken1 } from "../contracts/Price_Feed/PriceFeedToken1.sol";
import { PriceFeedToken2 } from "../contracts/Price_Feed/PriceFeedToken2.sol";


contract InitialTest is Test { 
    address public owner = makeAddr("owner");
    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");

    event DepositLiquidity(address indexed depositor, uint indexed amount, uint256 shares_minted, uint256 indexed depositCounter);

    Factory public factory;
    Router public router;
    LendingPoolCore public lendingPoolCoreToken1;
    LendingPoolCore public lendingPoolCoreToken2;
    LendTokens public lendTokens;
    Token1 public token1;
    Token2 public token2;
    PriceFeedToken1 public priceFeedToken1;
    PriceFeedToken2 public priceFeedToken2;

    function setUp() public  {
        vm.startPrank(bob);
        factory = new Factory();
        token1 = new Token1();
        token2 = new Token2();
        priceFeedToken1 = new PriceFeedToken1(8,3000e8);
        priceFeedToken2 = new PriceFeedToken2(8,7e8);
        lendTokens = new LendTokens();
        router = new Router(address(factory), [address(token1), address(token2)], [address(priceFeedToken1), address(priceFeedToken2)], address(lendTokens));
        lendTokens.transferOwnership(address(router));
        factory.setRouter(address(router));
        factory.createPool(address(token1), address(priceFeedToken1), address(lendTokens));
        factory.createPool(address(token2), address(priceFeedToken2), address(lendTokens));
        lendingPoolCoreToken1 = LendingPoolCore(factory.getPoolAddress(address(token1)));
        lendingPoolCoreToken2 = LendingPoolCore(factory.getPoolAddress(address(token2)));
        token1.transfer(address(lendingPoolCoreToken1),1e18);
        vm.stopPrank();
    }

    function test_ifthefactoryisdeployed() public view {
        console.log("Factory address: ", address(lendTokens));
        lendTokens.totalSupply();
        factory.getRouter();
    }   

    function test_depositofAsset() public {
        vm.startPrank(bob);
        token1.approve(address(router), 1000e18);
        uint256 x = token1.balanceOf(address(lendingPoolCoreToken1));
        router.depositLiquidity(address(token1), 1000e18);
        uint256 y = token1.balanceOf(address(lendingPoolCoreToken1));
        vm.stopPrank();
        lendingPoolCoreToken1.getRouter();
        console.log(address(router));
        console.log(lendingPoolCoreToken1.getTotalDepositAmount(bob));
        assert(x != y);

        uint balBOB = lendTokens.balanceOf(bob);
        assert(balBOB == 1e21);
    }

    function testCollateralValue() external {
        vm.startPrank(bob);
        token1.approve(address(router), 1000e18);
        router.depositLiquidity(address(token1), 1e18);
        vm.stopPrank();
        lendingPoolCoreToken1.getDepositValueInUSD(bob);
    }

    function testCheckDepositOfToken2() external {
        vm.startPrank(bob);
        token2.approve(address(router), 1000e8);
        router.depositLiquidity(address(token2), 17e8);
        // lendingPoolCoreToken2.depositLiquidityAndMintTokens(bob, 17e8);
        vm.stopPrank();
        lendingPoolCoreToken2.getDepositValueInUSD(bob);
    }

    function testDepositEventEmit() public {
        vm.startPrank(bob);
        token1.approve(address(router), 1000e18);
        vm.expectEmit(true,true,false,true);
        emit DepositLiquidity(bob, 1000e18,1000e18, 0);
        router.depositLiquidity(address(token1), 1000e18);
        vm.stopPrank();
    }

    function testSimpleWithdraw() public {
        vm.startPrank(bob);
        token1.approve(address(router), 1000e18);
        router.depositLiquidity(address(token1), 1000e18);
        assert(lendingPoolCoreToken1.getTotalDepositAmount(bob) == 1000e18);
        lendTokens.approve(address(router), 1e21);
        vm.warp(block.timestamp + 1000);
        router.withdrawDepositedFunds(address(token1), 1000e18, 0);
        assert(lendingPoolCoreToken1.getTotalDepositAmount(bob) == 0);
        assert(lendTokens.balanceOf(address(bob)) == 0);
        vm.stopPrank();
    }

//1000000000000000000000
//1000000000000000000000

    function testMultidepositandWithdraw() public {
        vm.startPrank(bob);
        token1.approve(address(router), 3000e18);
        router.depositLiquidity(address(token1), 1000e18);
        assert(lendingPoolCoreToken1.getTotalDepositAmount(bob) == 1000e18);
        router.depositLiquidity(address(token1), 1000e18);
        router.depositLiquidity(address(token1), 1000e18);
        assert(lendingPoolCoreToken1.getTotalDepositAmount(bob) == 3000e18);
        lendTokens.approve(address(router), 3e21);
        vm.warp(block.timestamp + 1000);
        lendTokens.balanceOf(bob);
        router.withdrawTotalUserDeposit(address(token1));
//        assert(lendingPoolCoreToken1.getDepositAmount(bob) == 0);
        vm.stopPrank();
    }

    function test_SimpleWithdrawPartialAmount() public {
        vm.startPrank(bob);
        uint256 x = token1.balanceOf(address(bob));
        console.log("The initial balance of bob ", x);
        token1.approve(address(router), 1000e18);
        router.depositLiquidity(address(token1), 1000e18);
        uint256 z = x - token1.balanceOf(address(bob));
        console.log("The balance of bob post the deposit : ", z);
        assert(lendingPoolCoreToken1.getTotalDepositAmount(bob) == 1000e18);
        lendTokens.approve(address(router), 1e21);
        vm.warp(block.timestamp + 1000);
        uint256 a = token1.balanceOf(bob);
        console.log("The balance of bob post the deposit : ", a);
        router.withdrawDepositedFunds(address(token1), 99918, 0);
//        assert(lendingPoolCoreToken1.getTotalDepositAmount(bob) == 900e18);
//        assert(lendTokens.balanceOf(address(bob)) == 900e18);
        vm.stopPrank();
        uint256 y = token1.balanceOf(address(bob));
        console.log("The balance of bob post the withdraw : ", y);
        assert(x > y);
    }

    function testFuzzMultiDepositAndWithdraw(uint256 amount) public {
        amount = bound(amount, 1e1, 1e17);
        vm.startPrank(bob);
        uint256 x = token1.balanceOf(address(bob));
        console.log("The initial balance of bob ", x);
        token1.approve(address(router), 1000e18);
        router.depositLiquidity(address(token1), 1000e18);
        uint256 z = x - token1.balanceOf(address(bob));
        console.log("The balance of bob post the deposit : ", z);
        assert(lendingPoolCoreToken1.getTotalDepositAmount(bob) == 1000e18);
        lendTokens.approve(address(router), amount);
        vm.warp(block.timestamp + 1000);
        uint256 a = token1.balanceOf(bob);
        console.log("The balance of bob post the deposit : ", a);
        router.withdrawDepositedFunds(address(token1), amount, 0);
        vm.stopPrank();
    }

    function testMultiDepositAndSemiWithdrawAsset(uint256[] calldata amounts) public {

    }

    function testTotalDepositValueInUSD() public {
        vm.startPrank(bob);
        priceFeedToken1.updateAnswer(5362e8);
        token1.approve(address(router), 1000e18);
        router.depositLiquidity(address(token1), 100e18);
        router.depositLiquidity(address(token1), 1e18);
        router.depositLiquidity(address(token1), 77e9);
        router.depositLiquidity(address(token1), 10e12);
        router.depositLiquidity(address(token1), 1012);
        router.depositLiquidity(address(token1), 10178324);
        uint256 x = router.getDepositsInUSD(address(token1));
        vm.stopPrank();
        console.log(x);
    }

    function testDepositCollateralSingle() public {
        vm.startPrank(bob);
        token1.approve(address(router), 1000e18);
        router.DepositCollateralSingle(address(token1), 1000e18);
        assert(lendTokens.balanceOf(bob) == 0);
        assert(lendingPoolCoreToken1.getCollateralAmount(bob) == 1000e18);
        vm.stopPrank();
    }

    function testDepositCollateralSingleAndValue(uint256 amount) public {
        amount = bound(amount, 1e1, 1000e18);
        vm.startPrank(bob);
        token1.approve(address(router), amount);
        router.DepositCollateralSingle(address(token1), amount);
        assert(lendTokens.balanceOf(bob) == 0);
        assert(lendingPoolCoreToken1.getCollateralAmount(bob) == amount);
        uint256 x = router.getCollateralValueInUSD(address(token1), bob);
        console.log(x ," is the value of the Collateral in usd");
        vm.stopPrank();
    }

    function testWithdrawUsingSameDepositId() public {
        vm.startPrank(bob);
        token1.approve(address(router), 1000e18);
        router.depositLiquidity(address(token1), 100e18);
        vm.warp(1000);
        lendTokens.approve(address(router), 1e22);
        router.withdrawDepositedFunds(address(token1), 100e18, 0);
        vm.expectRevert();
        router.withdrawDepositedFunds(address(token1), 100e18, 0);
        vm.stopPrank();
    }

    function testWithdrawUsingSameDepositIdDifferentAmounts() public {
//        amount1 = bound(amount1, 1e1, 100e18);
//        amount2 = bound(amount2, amount1, 100e18);
        vm.startPrank(bob);
        token1.approve(address(router), 1000e18);
        router.depositLiquidity(address(token1), 100e18);
        vm.warp(1000);
        lendTokens.approve(address(router), 1e22);
        router.withdrawDepositedFunds(address(token1), 10e18, 0);
        vm.expectRevert();
        router.withdrawDepositedFunds(address(token1), 91e18, 0);
        vm.stopPrank();
    }
}