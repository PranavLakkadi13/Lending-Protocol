// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { LendTokens } from "./LendTokens.sol";

contract LendingPoolCore {

    //////////////////////////////////
    // Errors and Events /////////////
    //////////////////////////////////

    error CoreLogic__OnlyRouter();
    error CoreLogic__OutOfBalance();

    event DepositLiquidity(address indexed depositor, uint indexed amount, uint256 shares_minted);
    event CollateralDeposited(address indexed depositor, uint indexed amount);

    //////////////////////////////////
    // State Variables ///////////////
    //////////////////////////////////
    struct Deposits {
        uint amount;
        uint256 timeOfdeposit;
    }

    struct TimeBasedDeposits {
        uint256[] depositCount;
        mapping(uint256 => Deposits) trackedDeposits;
        uint256 depositCounter;
    }

    ERC20 private immutable i_underlyingAsset;
    address private immutable i_poolFactory;
    LendTokens private immutable i_lendingToken;
    AggregatorV3Interface private immutable i_priceFeed;
    mapping(address => TimeBasedDeposits ) private s_userDeposits;
//    mapping(address => Deposits ) private s_userBorrowedAmount;
    mapping(address => uint256 ) private s_userCollateral;
    uint256 private constant BORROWING_RATIO = 150;
    uint256 private constant LIQUIDATION_TRESHOLD = 110;
    uint256 private constant WITHDRAWAL_INTEREST = 3;
    uint256 private constant PRECISION = 5;
    address private immutable i_Router;

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
         require(msg.sender == i_Router, "Only Router can call this function");
        SafeERC20.safeTransferFrom(i_underlyingAsset, depositor, address(this), amount);

        TimeBasedDeposits storage deposit = s_userDeposits[depositor];

        unchecked {
            deposit.trackedDeposits[deposit.depositCounter].amount = amount;
            deposit.trackedDeposits[deposit.depositCounter].timeOfdeposit = block.timestamp;
            deposit.depositCount.push(deposit.depositCounter);
            deposit.depositCounter++;
        }

        emit DepositLiquidity(depositor, amount, amount);
    }

    function depositCollateral(address depositor, uint256 amount) external onlyRouter {
        require(msg.sender == i_Router, "Only Router can call this function");
        SafeERC20.safeTransferFrom(i_underlyingAsset, depositor, address(this), amount);

        unchecked {
            s_userCollateral[depositor] += amount;
        }

        emit CollateralDeposited(depositor, amount);
    }

//    function withdrawLiquidity(address user, uint amount) external onlyRouter {
//        if (amount > s_userDeposits[user].amount && s_userDeposits[user].isCollateral == false) {
//            revert CoreLogic__OutOfBalance();
//        }
//
//
//        SafeERC20.safeTransfer(i_underlyingAsset, user, amount);
//        s_userDeposits[user].amount -= amount;
//    }

    //////////////////////////////////
    // Getters for core logic ////////
    //////////////////////////////////


    // will look into this 
    function getBorrowableAmountBasedOnUSDAmount(address user, uint collateralInUSD) external view returns (uint value) {
        uint8 temp = 18 - i_priceFeed.decimals();
        
    }

    /// To see the collateral value in USD
    /// @param user address of the user
    function getDepositValueInUSD(address user) public view returns (uint) {
        (,int price,,,) = i_priceFeed.latestRoundData();

        if (i_priceFeed.decimals() == 18) {
            return (getDepositAmount(user) * uint(price))/1e18;
        } 
        else { 
            uint8 temp = 18 - i_priceFeed.decimals();
            uint8 temp2 = 18 - i_underlyingAsset.decimals();
            return (getDepositAmount(user) * 10 ** temp2 * (uint(price) * (10 ** temp)))/ (10 ** 18);
        }
    }

    //////////////////////////////////
    // FlashLoan  ////////////////////
    //////////////////////////////////

    function FlashLoan(address receiver,uint amount) external onlyRouter {
        if (amount > i_underlyingAsset.balanceOf(address(this))) {
            revert CoreLogic__OutOfBalance();
        }
//        SafeERC20.safeTransfer(i_underlyingAsset, address(i_Router), amount);
        i_underlyingAsset.transfer(receiver, amount);
    }


    //////////////////////////////////
    // Getters for state variables ///
    //////////////////////////////////

    function getDepositAmount(address user) public view returns (uint256 depositedAmount) {
        for (uint i = 0; i < s_userDeposits[user].depositCounter; i++) {
            depositedAmount += s_userDeposits[user].trackedDeposits[s_userDeposits[user].depositCount[i]].amount;
        }
    }

//    function getBorrowedAmount(address user) external view returns (uint) {
//        return s_userBorrowedAmount[user].amount;
//    }

    function getCollateralAmount(address user) public view returns (uint) {
        return s_userCollateral[user];
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