// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LendingPoolCore } from "./CoreLogic.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Router } from "./Router.sol";

contract Factory is Ownable {

    error Factory__PoolExists();
    error Factory__ZeroAddress();
    error Factory__PoolCreationFailed();

    mapping(address => address) private getPool;
    address private  s_Router;
    address[] public allPools;

    event PoolCreated(address indexed token0, address pool, uint);

    constructor() Ownable(msg.sender) {}

    function setRouter(address router) external onlyOwner {
        if (s_Router == address(0)) {
            s_Router = router;
        }
    }

    function allPairsLength() external view returns (uint) {
        return allPools.length;
    }

    function createPool(address underlyingAsset, address pricefeedAddress) external returns (address pool) { 
        if (underlyingAsset == address(0)) {
            revert Factory__ZeroAddress();
        }
        if (getPool[underlyingAsset] != address(0)) {
            revert Factory__PoolExists();
        }
        bytes memory bytecode = type(LendingPoolCore).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(underlyingAsset, pricefeedAddress, s_Router));
        assembly {
            pool := create2(0xff, add(bytecode, 32), mload(bytecode), salt)
        }
        if (pool == address(0)) {
            revert Factory__PoolCreationFailed();
        }
        getPool[underlyingAsset] = pool;
        allPools.push(pool);
        emit PoolCreated(underlyingAsset, pool, allPools.length);
        return pool;
    }

    function getPoolAddress(address underlyingToken) external view returns (address) {
        return getPool[underlyingToken];
    }

    function getRouter() external view returns (address) {
        return s_Router;
    }
}