// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFlashLoanSimpleReceiver} from "../contracts/core/interface/IFlashLoanReceiver.sol";
import { Test, console } from "forge-std/Test.sol";
import { Factory } from "../contracts/core/Factory.sol";
import { Router } from "../contracts/core/Router.sol";
import { LendingPoolCore } from "../contracts/core/CoreLogic.sol";
import { LendTokens } from "../contracts/core/LendTokens.sol";
import { Token1 } from "../contracts/Tokens_ERC20/Token1.sol";
import { Token2 } from "../contracts/Tokens_ERC20/Token2.sol";
import { PriceFeedToken1 } from "../contracts/Price_Feed/PriceFeedToken1.sol";
import { PriceFeedToken2 } from "../contracts/Price_Feed/PriceFeedToken2.sol";

contract FlashLoanTest is IFlashLoanSimpleReceiver {
    address public immutable i_owner;
    ERC20 private immutable i_underlyingAsset;
    Router private immutable i_router;

    constructor(address token,address router){
        i_owner = msg.sender;
        i_underlyingAsset = ERC20(token);
        i_router = Router(router);
    }

    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, address pool) external override {
        console.log("FlashLoan executed");
        ERC20.approve(pool, _amount + _fee);
    }

    function flashLoan(uint256 amount) public {
        i_router.flashLoan(address(this), address(i_underlyingAsset), amount);
    }
}


contract FlashTest is Test {
    address public owner = makeAddr("owner");
    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");

    Factory public factory;
    Router public router;
    LendingPoolCore public lendingPoolCoreToken1;
    LendingPoolCore public lendingPoolCoreToken2;
    LendTokens public lendTokens;
    Token1 public token1;
    Token2 public token2;
    PriceFeedToken1 public priceFeedToken1;
    PriceFeedToken2 public priceFeedToken2;
    FlashLoanTest public test;

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
        test = new FlashLoanTest(address(token1), address(router));
        vm.stopPrank();
    }

    function test_flashLoanRevert() public {
        vm.expectRevert();

    }
}
