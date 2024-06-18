// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { LendTokens } from "./LendTokens.sol";

contract LendingPoolCore {

    //////////////////////////////////
    // State Variables ///////////////
    //////////////////////////////////

    IERC20 private immutable i_underlyingAsset;
    address private immutable i_poolFactory;
    LendTokens private immutable i_lendingToken;
    AggregatorV3Interface private immutable i_priceFeed;
    mapping(address => uint) private i_userDeposits;
    uint256 private constant BORROWING_RATIO = 150;
    uint256 private constant LIQUIDATION_TRESHOLD = 110;
    address private immutable i_Router;
    mapping(address => uint) private i_userBorrowedAmount;

    //////////////////////////////////
    // Modifier //////////////////////
    //////////////////////////////////

    modifier onlyRouter() {
        if (msg.sender != i_Router) {
            revert("Only Router can call this function");
            _;
        }
    }

    constructor (address token, address pricefeed, address router) {
        i_underlyingAsset = IERC20(token);
        i_poolFactory = msg.sender;
        i_lendingToken = LendTokens(address(new LendTokens()));
        i_priceFeed = AggregatorV3Interface(pricefeed); 
        i_Router = router;
    }

    //////////////////////////////////
    // core logic ////////////////////
    //////////////////////////////////

    function depositLiquidityAndMintTokens(address depositor, uint256 amount) external onlyRouter {
        SafeERC20.safeTransferFrom(i_underlyingAsset, depositor, address(this), amount);
        unchecked {
            i_userDeposits[depositor] += amount;
        }
        bool postmint = i_lendingToken.mint(depositor, amount);
        if (!postmint) {
            revert("Minting failed");
        }
    }

    //////////////////////////////////
    // Getters for core logic ////////
    //////////////////////////////////


    function getBorrowableAmountBasedOnUSDAmount(address user, uint collateralInUSD) external view returns (uint value) {
        uint8 temp = 18 - i_priceFeed.decimals();
        
    }

    function getCollateralValueInUSD(address user) external view returns (uint) {
        (,int price,,,) = i_priceFeed.latestRoundData();
        
        if (i_priceFeed.decimals() == 18) {
            return i_userDeposits[user] * uint(price);
        } 
        else { 
            uint8 temp = 18 - i_priceFeed.decimals();
            return (i_userDeposits[user] * (uint(price) * (10 ** temp)))/ (10 ** 18);
        }

    }

    //////////////////////////////////
    // Getters for state variables ///
    //////////////////////////////////

    function getCollateral(address user) external view returns (uint) {
        return i_userDeposits[user];
    }


    function assetAddress() external view returns (address) {
        return address(i_underlyingAsset);
    }

    function poolFactoryAddress() external view returns (address) {
        return i_poolFactory;
    }

    function lendingTokenAddress() external view returns (address) {
        return address(i_lendingToken);
    }

    function priceFeedAddress() external view returns (address) {
        return address(i_priceFeed);
    }
}