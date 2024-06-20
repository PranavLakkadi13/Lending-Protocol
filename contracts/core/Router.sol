// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Factory } from "./Factory.sol";
import { LendingPoolCore } from "./CoreLogic.sol";
import { LendTokens } from "./LendTokens.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IFlashLoanSimpleReceiver } from "./interface/IFlashLoanReceiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Router is Ownable {

    error Router__ZeroAddress();

    //////////////////////////////////
    // State Variables ///////////////
    //////////////////////////////////

    struct PoolLendPosition {
        address pool;
        uint amount;
    }

    Factory private immutable i_factory;
    mapping(address => address) private s_priceFeeds;
    LendTokens private immutable i_lendTokens;
    // uint256 public flashloanFee = 5;

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

    function withdrawDepositedFunds(address tokenToWithdraw, uint256 amount) external {
        if (tokenToWithdraw == address(0) || amount == 0) {
            revert Router__ZeroAddress();
        }

        address pool = Factory(i_factory).getPoolAddress(tokenToWithdraw);
        if (pool == address(0)) {
            revert Router__ZeroAddress();
        }

//        LendingPoolCore(pool).withdrawLiquidity(msg.sender, amount);
        burnLendTokens(msg.sender, amount);
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

    
    //////////////////////////////////
    //// Flash Loan /////////////////
    //////////////////////////////////

    function flashLoan(address token, uint256 amount) external {
        if (token == address(0) || amount == 0) {
            revert Router__ZeroAddress();
        }
        address pool = Factory(i_factory).getPoolAddress(token);
        if (address(pool) == address(0)) {
            revert Router__ZeroAddress();
        }

        uint256 flashloanFee = (amount * 5) / 10000;

        LendingPoolCore(pool).FlashLoan(msg.sender,amount);

        IFlashLoanSimpleReceiver(msg.sender).executeOperation(token, amount, flashloanFee);

        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount + flashloanFee);
        SafeERC20.safeTransfer(IERC20(token), address(pool), amount + flashloanFee);
    }

}