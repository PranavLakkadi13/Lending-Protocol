// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { Factory } from "../contracts/core/Factory.sol";
import { Router } from "../contracts/core/Router.sol";
import { LendingPoolCore } from "../contracts/core/CoreLogic.sol";
import { LendTokens } from "../contracts/core/LendTokens.sol";
import { Token1 } from "../contracts/Tokens_ERC20/Token1.sol";
import { Token2 } from "../contracts/Tokens_ERC20/Token2.sol";
import { PriceFeedToken1 } from "../contracts/Price_Feed/PriceFeedToken1.sol";
import { PriceFeedToken2 } from "../contracts/Price_Feed/PriceFeedToken2.sol";


contract InitialTest is Test { 
    address owner = makeAddr("owner");
    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    Factory factory;
    Router router;
    LendingPoolCore lendingPoolCore;
    LendTokens lendTokens;
    Token1 token1;
    Token2 token2;
    PriceFeedToken1 priceFeedToken1;
    PriceFeedToken2 priceFeedToken2;

    function setup() public  {
        vm.startPrank(bob);
        factory = new Factory();
        token1 = new Token1();
        token2 = new Token2();
        priceFeedToken1 = new PriceFeedToken1(18,3000);
        priceFeedToken2 = new PriceFeedToken2(18,1);
        lendTokens = new LendTokens();
        router = new Router(address(factory), [address(token1), address(token2)], [address(priceFeedToken1), address(priceFeedToken2)]);
        vm.stopPrank();
    }

    function test_ifthefactoryisdeployed() public {
        address x = factory.getPoolAddress(address(token1));
        assertEq(x, address(0));
    }
}