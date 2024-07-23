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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Factory} from "./Factory.sol";
import {LendingPoolCore} from "./CoreLogic.sol";
import {LendTokens} from "./LendTokens.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFlashLoanSimpleReceiver} from "./interface/IFlashLoanReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PercentageMath} from "./Library/PercentageLib.sol";
import "hardhat/console.sol";

contract Router is Ownable {
    error Router__ZeroAddress();
    error Router__AlreadyWithdrawnAmount();
    error Router__InvalidLength();

    //////////////////////////////////
    // State Variables ///////////////
    //////////////////////////////////

    struct PoolCollateralPosition {
        address pool;
        uint256 amount;
        uint256 amountValueInUSD;
    }

    struct PoolCollateralData {
        uint256 activePositions;
        mapping(uint256 => PoolCollateralPosition) positions;
    }

    Factory private immutable i_factory;
    mapping(address => address) private s_priceFeeds;
    LendTokens private immutable i_lendTokens;
    uint256 private constant FLASHLOAN_FEE = 5;
    mapping(address => PoolCollateralData) private s_poolCollateralData;

    constructor(address factory, address[] memory tokenAddress, address[] memory priceFeeds, address lendToken)
        Ownable(msg.sender)
    {
        if (factory == address(0) || lendToken == address(0)) {
            revert Router__ZeroAddress();
        }
        i_factory = Factory(factory);
        i_lendTokens = LendTokens(lendToken);
        uint256 lenToken = tokenAddress.length;
        uint256 lenPriceFeeds = priceFeeds.length;
        if (lenToken != lenPriceFeeds) {
            revert Router__InvalidLength();
        }
        for (uint256 i = 0; i < lenToken; i++) {
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

    function CreatePool(address token) external onlyOwner {
        if (token == address(0) || s_priceFeeds[token] == address(0)) {
            revert Router__ZeroAddress();
        }
        i_factory.createPool(token, s_priceFeeds[token], address(i_lendTokens));
    }

    //////////////////////////////////
    //// Borrow Functions ////////////
    //////////////////////////////////

    function borrow(address tokenToBorrow, address CollateralToken, uint256 amount, uint256 amountCollateral)
        external
    {
        if (tokenToBorrow == address(0) || amount == 0) {
            revert Router__ZeroAddress();
        }

        address pool = Factory(i_factory).getPoolAddress(tokenToBorrow);
        if (pool == address(0)) {
            revert Router__ZeroAddress();
        }

        //        LendingPoolCore(pool).borrow(msg.sender, amount);
        //        SafeERC20.safeTransfer(IERC20(tokenToBorrow), msg.sender, amount);
        DepositCollateralSingle(CollateralToken, amountCollateral);
        uint256 CollateralValue = LendingPoolCore(CollateralToken).getValueInUSD(amountCollateral);
        uint256 amountToBorrow = CollateralValue - ((CollateralValue * 70) / 100);
        console.log("Amount to Borrow", amountToBorrow);
        uint256 amountBorrowable = _getAmountBorrowable(tokenToBorrow, amount);
    }

    function _getAmountBorrowable(address token, uint256 amount) internal returns (uint256 borrowableAmount) {
        address pool = i_factory.getPoolAddress(token);
        if (pool == address(0)) {
            pool = i_factory.createPool(token, s_priceFeeds[token], address(i_lendTokens));
        }
        borrowableAmount = LendingPoolCore(pool).getValueInUSD(amount);
    }
    //////////////////////////////////
    //// Deposit Functions ///////////
    //////////////////////////////////

    function depositLiquidity(address tokenToDeposit, uint256 amount) external {
        if (tokenToDeposit == address(0) || amount == 0) {
            revert Router__ZeroAddress();
        }

        address pool;
        pool = Factory(i_factory).getPoolAddress(tokenToDeposit);
        if (pool == address(0)) {
            pool = i_factory.createPool(tokenToDeposit, s_priceFeeds[tokenToDeposit], address(i_lendTokens));
        }

        SafeERC20.safeTransferFrom(IERC20(tokenToDeposit), msg.sender, address(this), amount);
        LendingPoolCore(pool).depositLiquidityAndMintTokens(msg.sender, amount);
        SafeERC20.safeTransfer(IERC20(tokenToDeposit), pool, amount);
        mintLendTokens(msg.sender, amount);
    }

    function DepositCollateralSingle(address tokenToDeposit, uint256 amount) public {
        if (tokenToDeposit == address(0) || amount == 0) {
            revert Router__ZeroAddress();
        }

        address pool;
        pool = Factory(i_factory).getPoolAddress(tokenToDeposit);
        if (pool == address(0)) {
            pool = i_factory.createPool(tokenToDeposit, s_priceFeeds[tokenToDeposit], address(i_lendTokens));
        }

        s_poolCollateralData[msg.sender].positions[s_poolCollateralData[msg.sender].activePositions] =
            PoolCollateralPosition(pool, amount, LendingPoolCore(pool).getValueInUSD(amount));

        SafeERC20.safeTransferFrom(IERC20(tokenToDeposit), msg.sender, address(this), amount);
        LendingPoolCore(pool).depositCollateral(msg.sender, amount);

        unchecked {
            s_poolCollateralData[msg.sender].activePositions++;
        }

        SafeERC20.safeTransfer(IERC20(tokenToDeposit), pool, amount);
    }

    //////////////////////////////////
    ////  Withdraw Functions /////////
    //////////////////////////////////

    function withdrawDepositedFunds(address tokenToWithdraw, uint256 amount, uint256 depositId) public {
        if (tokenToWithdraw == address(0) || amount == 0) {
            revert Router__ZeroAddress();
        }

        address pool = Factory(i_factory).getPoolAddress(tokenToWithdraw);
        if (pool == address(0)) {
            revert Router__ZeroAddress();
        }

        LendingPoolCore(pool).withdrawLiquidity(msg.sender, amount, depositId);
        SafeERC20.safeTransferFrom(IERC20(i_lendTokens), msg.sender, address(this), amount);
        burnLendTokens(msg.sender, amount);
    }

    function withdrawTotalUserDeposit(address tokenToWithdraw) external {
        if (tokenToWithdraw == address(0) || i_factory.getPoolAddress(tokenToWithdraw) == address(0)) {
            revert Router__ZeroAddress();
        }
        address pool = i_factory.getPoolAddress(tokenToWithdraw);

        uint256 amount = LendingPoolCore(pool).getTotalDepositAmount(msg.sender);
        if (amount == 0) {
            revert Router__AlreadyWithdrawnAmount();
        }
        LendingPoolCore(pool).withdrawTotalAmount(msg.sender);
        SafeERC20.safeTransferFrom(IERC20(i_lendTokens), msg.sender, address(this), amount);
        burnLendTokens(msg.sender, amount);
    }

    function withdrawMultipleDepositsSameAsset(
        address tokensToWithdraw,
        uint256[] calldata depositIds,
        uint256[] calldata depositAmounts
    ) external {
        for (uint256 i = 0; i < depositIds.length; i++) {
            withdrawDepositedFunds(tokensToWithdraw, depositAmounts[i], depositIds[i]);
        }
    }

    //////////////////////////////////
    //// Liquidate Functions /////////
    //////////////////////////////////

    //////////////////////////////////
    //// LEND Tokens Manager /////////
    //////////////////////////////////

    function mintLendTokens(address account, uint256 amount) internal {
        i_lendTokens.mint(account, amount);
    }

    function burnLendTokens(address account, uint256 amount) internal {
        i_lendTokens.burn(amount);
    }

    //////////////////////////////////
    //// Flash Loan //////////////////
    //////////////////////////////////

    function flashLoan(address token, uint256 amount) external {
        if (token == address(0) || amount == 0) {
            revert Router__ZeroAddress();
        }
        address pool = Factory(i_factory).getPoolAddress(token);
        if (address(pool) == address(0)) {
            revert Router__ZeroAddress();
        }

        //Flash Loan Amount =
        //        1e18 = >    1000000000000000000
        //  Percent Mul= >        500000000000000  when the amount is 1e18 and % is 5
        //  Percent Mul =>       5000000000000000  when the amount is 1e18 and % is 50
        //             = >    1005000000000000000  the final to be paid back by the borrower when the fee is 0.5%
        //              = >   1000500000000000000  the fee to be paid back when the fee is 5 i.e 0.05%
        uint256 flashloanFee = PercentageMath.percentMul((amount), FLASHLOAN_FEE);

        LendingPoolCore(pool).FlashLoan(msg.sender, amount);

        IFlashLoanSimpleReceiver(msg.sender).executeOperation(token, amount, flashloanFee);

        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount + flashloanFee);
        SafeERC20.safeTransfer(IERC20(token), address(pool), amount + flashloanFee);
    }

    //////////////////////////////////
    //// Getter Functions ////////////
    //////////////////////////////////

    function getFlashLoanFee() external pure returns (uint256) {
        return FLASHLOAN_FEE;
    }

    function getLendTokens() external view returns (address) {
        return address(i_lendTokens);
    }

    function getFactory() external view returns (address) {
        return address(i_factory);
    }

    function getPoolAddress(address token) public view returns (address) {
        return i_factory.getPoolAddress(token);
    }

    function getDepositsInUSD(address token) public view returns (uint256) {
        address pool = i_factory.getPoolAddress(token);
        return LendingPoolCore(pool).getDepositValueInUSD(msg.sender);
    }

    function getCollateralValueInUSD(address token, address user) public view returns (uint256) {
        address pool = i_factory.getPoolAddress(token);
        return LendingPoolCore(pool).getCollateralValueInUSD(user);
    }
}
