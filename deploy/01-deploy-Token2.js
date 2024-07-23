const { ethers, network } = require("hardhat");
// const { verify } = require("../utils/verify.js");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  let token2;
  let args;

  log("--------------------------------------------------");
  log(`2. Deploying Token2 ..................... `);
  token2 = await deploy("Token2", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  // if (
  //     !developmentChain.includes(network.name)
  // ) {
  //   await verify(DecentralisedStableCoin.address, args);
  // }

  log("--------------------------------------------------");
  log("Token2 deployed at: " + (await token2.address));
  log("--------------------------------------------------");
};

module.exports.tags = ["Token2"];
