// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Factory } from "./Factory.sol";
import { LendingPoolCore } from "./CoreLogic.sol";
import { LendTokens } from "./LendTokens.sol";

contract Router {

    struct PoolDepositPosition{
        address pool;
        uint amount;
    }

    struct PoolLendPosition {
        address pool;
        uint amount;
    }

    address private immutable i_factory;
    
    constructor (address factory) {
        i_factory = factory;
    }
}