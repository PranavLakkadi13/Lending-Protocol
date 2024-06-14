// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import  { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract LendingPoolCore {

    IERC20 public immutable i_underlyingAsset;
    constructor (address token) {
        i_underlyingAsset = IERC20(token);
    }
}