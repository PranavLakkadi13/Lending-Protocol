const { ethers } = require("hardhat");

// Pricefeed for the token 1 
const Token1Args = ["18", ethers.utils.parseUnits("3000","8")]; 

const Token2Args = ["8", ethers.utils.parseUnits("1","8")];



module.exports = {
    Token1Args,
    Token2Args,
}