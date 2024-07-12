//   mmm                                       mmm  #               "
//   m"   "  m mm   mmm    mmm    mmm          m"   " # mm    mmm   mmm    m mm
//   #       #"  " #" "#  #   "  #   "         #      #"  #  "   #    #    #"  #
//   #       #     #   #   """m   """m   """   #      #   #  m"""#    #    #   #
//   "mmm"  #     "#m#"  "mmm"  "mmm"          "mmm" #   #  "mm"#  mm#mm  #   #
//
//
//
//   m                        #    "
//   #       mmm   m mm    mmm#  mmm    m mm    mmmm
//   #      #"  #  #"  #  #" "#    #    #"  #  #" "#
//   """   #      #""""  #   #  #   #    #    #   #  #   #
//   #mmmmm "#mm"  #   #  "#m##  mm#mm  #   #  "#m"#
//


/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { LendTokens } from "./LendTokens.sol";
//import { console } from "hardhat/console.sol";
import { console } from "forge-std/console.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract LendingPoolCore {

    //////////////////////////////////
    // Errors and Events /////////////
    //////////////////////////////////

    error CoreLogic__OnlyRouter();
    error CoreLogic__OutOfBalance();
    error CoreLogic__InvalidDepositId();

    event DepositLiquidity(address indexed depositor, uint indexed amount, uint256 shares_minted, uint256 indexed depositCounter);
    event CollateralDeposited(address indexed depositor, uint indexed amount);
    event SimpleWithdraw(address indexed depositor, uint indexed amount, uint256 indexed depositCounter);

    //////////////////////////////////
    // State Variables ///////////////
    //////////////////////////////////
    struct Deposits {
        uint amount;
        uint256 timeOfDeposit;
    }

    struct TimeBasedDeposits {
        uint256[] depositsThatAreWithdrawn;
        mapping(uint256 => bool) isWithdrawn;
        mapping(uint256 => Deposits) trackedDeposits;
        uint256 depositCounter;
        uint256 totalDepositedAmount;
    }

    ERC20 private immutable i_underlyingAsset;
    address private immutable i_poolFactory;
    LendTokens private immutable i_lendingToken;
    AggregatorV3Interface private immutable i_priceFeed;
    mapping(address => TimeBasedDeposits ) private s_userDeposits;
//    mapping(address => Deposits ) private s_userBorrowedAmount;
    mapping(address => uint256 ) private s_userCollateral;
    uint256 private s_TotalUserCollateral;
    uint256 private constant BORROWING_RATIO = 150;
    uint256 private constant LIQUIDATION_TRESHOLD = 110;
    uint256 private constant WITHDRAWAL_INTEREST = 3;
    uint256 private constant PRECISION = 5;
    address private immutable i_Router;
    uint256 private s_totalUserDeposits;
    uint256 private s_totalUserCounter;
	
    //////////////////////////////////
    // Modifier //////////////////////
    //////////////////////////////////

    modifier onlyRouter() {
        if (msg.sender == address(i_Router)) {
            // revert CoreLogic__OnlyRouter();
            _;
        }
    }

    constructor (address token, address priceFeed, address router, address lendToken) {
        i_underlyingAsset = ERC20(token);
        i_poolFactory = msg.sender;
        i_lendingToken = LendTokens(lendToken);
        i_priceFeed = AggregatorV3Interface(priceFeed);
        i_Router = router;
    }

    //////////////////////////////////
    //////////////////////////////////
    // CORE LOGIC ////////////////////
    //////////////////////////////////
    //////////////////////////////////

    //////////////////////////////////
    ////  Deposit Functions //////////
    //////////////////////////////////

    /// @notice This function is used to deposit the liquidity
    /// @param depositor address of the depositor
    /// @param amount amount of tokens
    /// @dev only the router contract can call this function
    function depositLiquidityAndMintTokens(address depositor, uint256 amount) external onlyRouter {
         require(msg.sender == i_Router, "Only Router can call this function");

        TimeBasedDeposits storage deposit = s_userDeposits[depositor];

        unchecked {
            deposit.trackedDeposits[deposit.depositCounter].amount = amount;
            deposit.trackedDeposits[deposit.depositCounter].timeOfDeposit = block.timestamp;
            deposit.totalDepositedAmount += amount;
            s_totalUserDeposits += amount;
            s_totalUserCounter++;
  }

//        s_userDeposits[depositor] = deposit;
        emit DepositLiquidity(depositor, amount, amount, deposit.depositCounter);

        deposit.depositCounter++;

    }


    function depositCollateral(address depositor, uint256 amount) external onlyRouter {
        require(msg.sender == i_Router, "Only Router can call this function");

        unchecked {
            s_userCollateral[depositor] += amount;
            s_TotalUserCollateral += amount;
        }

        emit CollateralDeposited(depositor, amount);
    }


    //////////////////////////////////
    ////  Withdraw Functions /////////
    //////////////////////////////////


    function withdrawLiquidity(address user, uint amount, uint256 depositId) public onlyRouter {
        require(msg.sender == i_Router, "Only router can call this function");
        if (s_userDeposits[user].depositCounter < depositId) {
            revert CoreLogic__InvalidDepositId();
        }
        TimeBasedDeposits storage deposit = s_userDeposits[user];

        uint256 totalBalance = i_underlyingAsset.balanceOf(address(this));
        console.log("Total Balance is ", totalBalance);

        if (amount == deposit.trackedDeposits[depositId].amount) {
            deposit.trackedDeposits[depositId].amount -= amount;
            deposit.totalDepositedAmount -= amount;
            deposit.depositsThatAreWithdrawn.push(depositId);
            deposit.isWithdrawn[depositId] = true;
            s_totalUserDeposits -= amount;
            s_totalUserCounter--;

            uint256 amountWIthInterest = _calculateTheAmountOfTokensToReturn(amount, deposit.trackedDeposits[depositId].timeOfDeposit, totalBalance);
            console.log("Amount With Interest is ", amountWIthInterest);

            SafeERC20.safeTransfer(i_underlyingAsset, user, amountWIthInterest);

            emit SimpleWithdraw(user, amountWIthInterest, depositId);
        }
        else {
            deposit.trackedDeposits[depositId].amount -= amount;
            deposit.totalDepositedAmount -= amount;
            s_totalUserDeposits -= amount;

            uint256 amountWIthInterest = _calculateTheAmountOfTokensToReturn(amount, deposit.trackedDeposits[depositId].timeOfDeposit, totalBalance);
            console.log("Amount With Interest is ", amountWIthInterest);

            SafeERC20.safeTransfer(i_underlyingAsset, user, amountWIthInterest);

            emit SimpleWithdraw(user, amountWIthInterest, depositId);
        }
    }

    function withdrawTotalAmount(address user) public onlyRouter {
        require(msg.sender == i_Router, "Only router can call this function");
        uint256 amountToWithdraw = getTotalDepositAmount(user);
        for (uint i = 0; i < s_userDeposits[user].depositCounter; i++) {
            if (!s_userDeposits[user].isWithdrawn[i]) {
                uint256 amountInThatDepositId = s_userDeposits[user].trackedDeposits[i].amount;
                withdrawLiquidity(user, amountInThatDepositId, i);
            }
        }
    }

    //////////////////////////////////
    // Getters for core logic ////////
    //////////////////////////////////

    function _calculateTheAmountOfTokensToReturn(uint256 amount, uint256 timeOfDeposit, uint256 BalanceOfContract) internal view returns (uint amountWithInterest) {
        if(BalanceOfContract == amount ){
            amountWithInterest = amount + getTotalInterestAmount(BalanceOfContract, amount);
            console.log("Hello");
        }
        else {
            console.log("Hello");
            uint256 timePassed = block.timestamp - timeOfDeposit;
            uint256 totalUserDepositAmount = BalanceOfContract - amount;
            uint256 TotalAccruedInterestAmount =  getTotalInterestAmount(BalanceOfContract, amount);
            console.log("Total Accrued Interest Amount is ", TotalAccruedInterestAmount);

            // The error is here when the amount is small like dust amount
            // To deal with dust amount we can use the dust value to calculate the interest on that amount as a separate deal
            uint256 getPercentAmount = amount * 100 / totalUserDepositAmount;
            if (getPercentAmount == 0) {
                uint256 assumedInterest = amount - ((amount * 98) / 100);
                amountWithInterest = amount + assumedInterest;
                console.logUint(amountWithInterest);
                return amountWithInterest;
            }

            uint256 interestAMountPerSecond = (TotalAccruedInterestAmount) / 52 weeks;
            uint256 interestAmountTotal = interestAMountPerSecond * (timePassed);
            amountWithInterest = amount + (interestAmountTotal/getPercentAmount);
            return amountWithInterest;
        }
    }


    function getTotalInterestAmount(uint256 BalAMount, uint256 amount) public view returns (uint) {
//        return BalAMount - (s_totalUserDeposits + s_TotalUserCollateral) - amount ;
        return BalAMount - (s_totalUserDeposits + s_TotalUserCollateral);
        // 1000000000318287037037
        // 1000000000000317969067
    }


    // will look into this 
    function getBorrowableAmountBasedOnUSDAmount(address user, uint collateralInUSD) external view returns (uint value) {
        uint8 temp = 18 - i_priceFeed.decimals();
        
    }

    /// To see the deposit value in USD
    /// @param user address of the user
    /// @return the value of the deposit in USD
    function getDepositValueInUSD(address user) public view returns (uint) {
//        (,int price,,,) = i_priceFeed.latestRoundData();
//
//        if (i_priceFeed.decimals() == 18) {
//            return (getTotalDepositAmount(user) * uint(price))/1e18;
//        }
//        else {
//            uint8 temp = 18 - i_priceFeed.decimals();
//            uint8 temp2 = 18 - i_underlyingAsset.decimals();
//            return (getTotalDepositAmount(user) * 10 ** temp2 * (uint(price) * (10 ** temp)))/ (10 ** 18);
//        }
        uint256 amount = getTotalDepositAmount(user);
        return getValueInUSD(amount);
    }

    /// To see the collateral value in USD
    /// @param user address of the user
    /// @return value in USD
    function getCollateralValueInUSD(address user) public view returns (uint) {
//        (,int price,,,) = i_priceFeed.latestRoundData();
//
//        if (i_priceFeed.decimals() == 18) {
//            return (getCollateralAmount(user) * uint(price))/1e18;
//        }
//        else {
//            uint8 temp = 18 - i_priceFeed.decimals();
//            uint8 temp2 = 18 - i_underlyingAsset.decimals();
//            return (getCollateralAmount(user) * 10 ** temp2 * (uint(price) * (10 ** temp)))/ (10 ** 18);
//        }
        uint256 amount = getCollateralAmount(user);
        return getValueInUSD(amount);
    }

    function getValueInUSD(uint amount) public view returns (uint) {
        (,int price,,,) = i_priceFeed.latestRoundData();

        if (i_priceFeed.decimals() == 18) {
            return (amount * uint(price))/1e18;
        }
        else {
            uint8 temp = 18 - i_priceFeed.decimals();
            uint8 temp2 = 18 - i_underlyingAsset.decimals();
            return (amount * 10 ** temp2 * (uint(price) * (10 ** temp)))/ (10 ** 18);
        }
    }

    //////////////////////////////////
    // FlashLoan  ////////////////////
    //////////////////////////////////

    /// @notice This function is used to flash loan the amount of tokens
    /// @param receiver address of the receiver
    /// @param amount amount of tokens
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

    /// @notice This function is used to get the total deposit amount of the user
    /// @param user address of the user
    /// @return the total deposited amount
    function getTotalDepositAmount(address user) public view returns (uint256) {
        return s_userDeposits[user].totalDepositedAmount;
    }

    /// @notice This function is used to get the deposit amount of a particular depositId
    /// @param user address of the user
    /// @param depositId id of the deposit
    /// @return the amount of the deposit
    function getIndividualDepositAmount(address user, uint256 depositId) public view returns (uint256) {
        return s_userDeposits[user].trackedDeposits[depositId].amount;
    }

//    function getBorrowedAmount(address user) external view returns (uint) {
//        return s_userBorrowedAmount[user].amount;
//    }

    /// @notice This function is used to get the total collateral amount of the user
    /// @param user address of the user
    /// @return the total collateral amount
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

    function getTotalUserDeposits() public view returns (uint256) {
        return s_totalUserDeposits;
    }

    function getTotalUserCounter() external view returns (uint256) {
        return s_totalUserCounter;
    }

    function getDepositInterestRate() external pure returns (uint256) {
        return WITHDRAWAL_INTEREST;
    }

}
