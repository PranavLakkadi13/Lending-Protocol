// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { Token1 } from  "../contracts/Tokens_ERC20/Token1.sol";


contract Target {

}

contract generic_Concept_Testing {
    Token1 public token1;

    function setUp() public {
        token1 = new Token1();
    }
}
