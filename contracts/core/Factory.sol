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

import {LendingPoolCore} from "./CoreLogic.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Router} from "./Router.sol";

contract Factory is Ownable {
    error Factory__PoolExists();
    error Factory__ZeroAddress();
    error Factory__PoolCreationFailed();

    mapping(address => address) private getPool;
    address private s_Router;
    address[] public allPools;

    event PoolCreated(address indexed token0, address pool, uint256);

    constructor() Ownable(msg.sender) {}

    function setRouter(address router) external onlyOwner {
        if (s_Router == address(0)) {
            s_Router = router;
        }
    }

    function allPairsLength() external view returns (uint256) {
        return allPools.length;
    }

    function createPool(address underlyingAsset, address pricefeedAddress, address lendToken)
        external
        returns (address pool)
    {
        if (underlyingAsset == address(0)) {
            revert Factory__ZeroAddress();
        }
        if (getPool[underlyingAsset] != address(0)) {
            revert Factory__PoolExists();
        }
        bytes memory bytecode = type(LendingPoolCore).creationCode;

        bytes memory endOutput =
            abi.encodePacked(bytecode, abi.encode(underlyingAsset, pricefeedAddress, s_Router, lendToken));

        bytes32 salt = keccak256(abi.encodePacked(underlyingAsset, pricefeedAddress, s_Router, lendToken));

        assembly {
            pool := create2(0, add(endOutput, 32), mload(endOutput), salt)
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
