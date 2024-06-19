// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { LendTokens } from "./LendTokens.sol";

contract LendingPoolCore {

    error CoreLogic__OnlyRouter();

    //////////////////////////////////
    // State Variables ///////////////
    //////////////////////////////////
    struct Deposits {
        uint amount;
        bool isCollateral;
    }

    ERC20 private immutable i_underlyingAsset;
    address private immutable i_poolFactory;
    LendTokens private immutable i_lendingToken;
    AggregatorV3Interface private immutable i_priceFeed;
    mapping(address => Deposits ) private i_userDeposits;
    uint256 private constant BORROWING_RATIO = 150;
    uint256 private constant LIQUIDATION_TRESHOLD = 110;
    address private immutable i_Router;
    mapping(address => uint) private i_userBorrowedAmount;

    //////////////////////////////////
    // Modifier //////////////////////
    //////////////////////////////////

    modifier onlyRouter() {
        if (msg.sender == address(i_Router)) {
            // revert CoreLogic__OnlyRouter();
            _;
        }
    }

    constructor (address token, address pricefeed, address router, address lendToken) {
        i_underlyingAsset = ERC20(token);
        i_poolFactory = msg.sender;
        i_lendingToken = LendTokens(lendToken);
        i_priceFeed = AggregatorV3Interface(pricefeed); 
        i_Router = router;
    }

    //////////////////////////////////
    // core logic ////////////////////
    //////////////////////////////////

    function depositLiquidityAndMintTokens(address depositor, uint256 amount) external onlyRouter {
        // require(msg.sender == i_Router, "Only Router can call this function");
        SafeERC20.safeTransferFrom(i_underlyingAsset, depositor, address(this), amount);
        
        Deposits storage deposit = i_userDeposits[depositor];
        
        if (deposit.amount == 0) {
            deposit.amount = amount;
        }
        else {
            deposit.amount += amount;
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
            return (i_userDeposits[user].amount * uint(price));
        } 
        else { 
            uint8 temp = 18 - i_priceFeed.decimals();
            return (i_userDeposits[user].amount * (uint(price) * (10 ** temp)))/ (10 ** 18);
        }
    }

    //////////////////////////////////
    // Getters for state variables ///
    //////////////////////////////////

    function getCollateral(address user) external view returns (uint) {
        return i_userDeposits[user].amount;
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

    function getRouter() external view returns (address) {
        return i_Router;
    }
}