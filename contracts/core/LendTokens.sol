// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract LendTokens is ERC20, ERC20Burnable, Ownable {

    constructor() 
    ERC20("TheLendTokens", "LTokens") 
    Ownable(msg.sender) {}

    function burn(uint256 amount) public override onlyOwner {
        _burn(msg.sender, amount);
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }
}