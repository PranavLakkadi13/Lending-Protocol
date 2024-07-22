// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token1 is ERC20 {
    constructor() ERC20("Token1", "TK1") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
