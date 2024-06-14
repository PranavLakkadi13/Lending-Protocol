const { ethers } = require("hardhat");

const Token1Args = ["18", ethers.utils.parseEther("3000")]; 

const Token2Args = ["8", ethers.utils.parseEther("300")];



module.exports = {
    Token1Args,
    Token2Args,
}