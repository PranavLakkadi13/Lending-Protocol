const { ethers, network } = require("hardhat");
// const { verify } = require("../utils/verify.js");

module.exports = async ({ getNamedAccounts, deployments }) => { 
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    let token1;
    let args;

    log("--------------------------------------------------");
    log(`1. Deploying Token1 ..................... `);
    token1 = await deploy("Token1", {
      from: deployer,
      args: [],
      log: true,
      waitConfirmations: network.config.blockConfirmations || 1,
    });

    // if (
    //     !developmentChain.includes(network.name)
    // ) {
    //     await verify(DecentralisedStableCoin.address, args);
    // }

    log("--------------------------------------------------");
    log("Token1 deployed at: " + (await token1.address));
    log("--------------------------------------------------");
}

module.exports.tags = ["Token1"];