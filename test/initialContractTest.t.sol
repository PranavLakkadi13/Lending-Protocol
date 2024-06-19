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

    Factory public factory;
    Router public router;
    LendingPoolCore public lendingPoolCoreToken1;
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
        priceFeedToken2 = new PriceFeedToken2(8,1e8);
        lendTokens = new LendTokens();
        router = new Router(address(factory), [address(token1), address(token2)], [address(priceFeedToken1), address(priceFeedToken2)], address(lendTokens));
        lendTokens.transferOwnership(address(router));
        factory.setRouter(address(router));
        factory.createPool(address(token1), address(priceFeedToken1), address(lendTokens));
        lendingPoolCoreToken1 = LendingPoolCore(factory.getPoolAddress(address(token1)));
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
        console.log(lendingPoolCoreToken1.getCollateral(bob));
        assert(x != y);

        uint balBOB = lendTokens.balanceOf(bob);
        assert(balBOB == 1e21);
    }

    function testCollateralValue() external {
        vm.startPrank(bob);
        token1.approve(address(lendingPoolCoreToken1), 1000e18);
        router.depositLiquidity(address(token1), 1e18);
        vm.stopPrank();
        lendingPoolCoreToken1.getCollateralValueInUSD(bob);
    }
}