// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { Token1 } from  "../contracts/Tokens_ERC20/Token1.sol";
import { PercentageMath } from "../contracts/core/Library/PercentageLib.sol";


contract generic_Concept_Testing is Test {

    function test_percentageMath() public {
        uint256 x = PercentageMath.percentMul(70, 25);
        console.log("Percentage of 7000 with 100% is: ", x);
        uint256 z = PercentageMath.percentMul(1000, 10);
        console.log("The value : ", z);
    }

    function test_percentageMathDiv() public {
        uint256 x = PercentageMath.percentDiv(7000, 25);
        console.log("10% of 1000 is: ", x);
//        assert(x == 100000);
    }
}
