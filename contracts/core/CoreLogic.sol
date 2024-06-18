// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { LendTokens } from "./LendTokens.sol";

contract LendingPoolCore {

    IERC20 private immutable i_underlyingAsset;
    address private immutable i_poolFactory;
    IERC20 private immutable i_lendingToken;
    AggregatorV3Interface private immutable i_priceFeed;

    constructor (address token, address pricefeed) {
        i_underlyingAsset = IERC20(token);
        i_poolFactory = msg.sender;
        i_lendingToken = IERC20(address(new LendTokens()));
        i_priceFeed = AggregatorV3Interface(pricefeed); 
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