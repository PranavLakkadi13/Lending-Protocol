// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Factory } from "./Factory.sol";
import { LendingPoolCore } from "./CoreLogic.sol";
import { LendTokens } from "./LendTokens.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Router is Ownable {

    error Router__ZeroAddress();

    //////////////////////////////////
    // State Variables ///////////////
    //////////////////////////////////

    struct PoolDepositPosition{
        address pool;
        uint amount;
    }

    struct PoolLendPosition {
        address pool;
        uint amount;
    }

    Factory private immutable i_factory;
    mapping(address => address) private s_priceFeeds;
    LendTokens private immutable i_lendTokens;

    constructor (address factory, address[2] memory tokenAddress, address[2] memory priceFeeds, address lendToken) 
    Ownable (msg.sender) {
        if (factory == address(0) || lendToken == address(0)) {
            revert Router__ZeroAddress();
        }
        i_factory = Factory(factory);
        i_lendTokens = LendTokens(lendToken);
        for (uint i = 0; i < 2; i++) {
            if (tokenAddress[i] == address(0) || priceFeeds[i] == address(0)) {
                revert Router__ZeroAddress();
            }
            s_priceFeeds[tokenAddress[i]] = priceFeeds[i];
        }
    }

    //////////////////////////////////
    ////  core logic /////////////////
    //////////////////////////////////

    function setPriceFeeds(address underlyingToken, address priceFeed) external onlyOwner {
        if (underlyingToken == address(0) || priceFeed == address(0)) {
            revert Router__ZeroAddress();
        }
        if (s_priceFeeds[underlyingToken] == address(0)) {
            s_priceFeeds[underlyingToken] = priceFeed;
        }
    }

    function depositLiquidity(address tokenToDeposit, uint256 amount) external {
        if (tokenToDeposit == address(0) || amount == 0) {
            revert Router__ZeroAddress();
        }

        address pool;
        pool = Factory(i_factory).getPoolAddress(tokenToDeposit);
        if (pool == address(0)) {
            pool = i_factory.createPool(tokenToDeposit, s_priceFeeds[tokenToDeposit], address(i_lendTokens));
        }
        
        LendingPoolCore(pool).depositLiquidityAndMintTokens(msg.sender, amount);
        mintLendTokens(msg.sender, amount);
    }

    //////////////////////////////////
    //// LEND Tokens Manager /////////
    //////////////////////////////////

    function mintLendTokens(address account, uint256 amount) internal {
        i_lendTokens.mint(account, amount);
    }

    function burnLendTokens(address account ,uint256 amount) internal {
        i_lendTokens.burn(amount);
    }

}