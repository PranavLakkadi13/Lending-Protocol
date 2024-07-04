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
        vm.stopPrank();
    }

    function test_ifthefactoryisdeployed() public view {
        console.log("Factory address: ", address(lendTokens));
        lendTokens.totalSupply();
        factory.getRouter();
    }   

    function test_depositofAsset() public {
        vm.startPrank(bob);
        token1.approve(address(lendingPoolCoreToken1), 1000e18);
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
        token1.approve(address(lendingPoolCoreToken1), 1000e18);
        router.depositLiquidity(address(token1), 1e18);
        vm.stopPrank();
        lendingPoolCoreToken1.getDepositValueInUSD(bob);
    }

    function testCheckDepositOfToken2() external {
        vm.startPrank(bob);
        token2.approve(address(lendingPoolCoreToken2), 1000e8);
        router.depositLiquidity(address(token2), 17e8);
        // lendingPoolCoreToken2.depositLiquidityAndMintTokens(bob, 17e8);
        vm.stopPrank();
        lendingPoolCoreToken2.getDepositValueInUSD(bob);
    }

    function testDepositEventEmit() public {
        vm.startPrank(bob);
        token1.approve(address(lendingPoolCoreToken1), 1000e18);
        vm.expectEmit(true,true,false,true);
        emit DepositLiquidity(bob, 1000e18,1000e18, 0);
        router.depositLiquidity(address(token1), 1000e18);
        vm.stopPrank();
    }

    function testSimpleWithdraw() public {
        vm.startPrank(bob);
        token1.approve(address(lendingPoolCoreToken1), 1000e18);
        router.depositLiquidity(address(token1), 1000e18);
        assert(lendingPoolCoreToken1.getTotalDepositAmount(bob) == 1000e18);
        lendTokens.approve(address(router), 1e21);
        vm.warp(block.timestamp + 1000);
        router.withdrawDepositedFunds(address(token1), 1000e18, 0);
        assert(lendingPoolCoreToken1.getTotalDepositAmount(bob) == 0);
        assert(lendTokens.balanceOf(address(bob)) == 0);
        vm.stopPrank();
    }

    function testMultidepositandWithdraw() public {
        vm.startPrank(bob);
        token1.approve(address(lendingPoolCoreToken1), 3000e18);
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
        token1.approve(address(lendingPoolCoreToken1), 1000e18);
        router.depositLiquidity(address(token1), 1000e18);
        uint256 z = x - token1.balanceOf(address(bob));
        console.log("The balance of bob post the deposit : ", z);
        assert(lendingPoolCoreToken1.getTotalDepositAmount(bob) == 1000e18);
        lendTokens.approve(address(router), 1e21);
        vm.warp(block.timestamp + 1000);
        uint256 a = token1.balanceOf(bob);
        console.log("The balance of bob post the deposit : ", a);
        router.withdrawDepositedFunds(address(token1), 100e18, 0);
        assert(lendingPoolCoreToken1.getTotalDepositAmount(bob) == 900e18);
        assert(lendTokens.balanceOf(address(bob)) == 900e18);
        vm.stopPrank();
        uint256 y = token1.balanceOf(address(bob));
        console.log("The balance of bob post the withdraw : ", y);
        assert(x > y);
    }

    function testFuzzMultiDepositAndWithdraw(uint256[] calldata amounts) public {

    }

    function testMultiDepositAndSemiWithdrawAsset(uint256[] calldata amounts) public {

    }
}