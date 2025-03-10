// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract PriceFeedToken2 is MockV3Aggregator {
    constructor(uint8 decimal, int256 _initialAnswer) public MockV3Aggregator(decimal, _initialAnswer) {}
}
