const { ethers, network } = require("hardhat");
const { Token1Args } = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  let PriceFeedToken1;

  log("--------------------------------------------------");
  log(`3. Deploying PriceFeedToken1 Contract ..................... `);
  PriceFeedToken1 = await deploy("PriceFeedToken1", {
    from: deployer,
    args: [Token1Args[0], Token1Args[1]],
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  log("--------------------------------------------------");
  log("PriceFeedToken1 Contract deployed at: " + (await PriceFeedToken1.address));
  log("--------------------------------------------------");

};

module.exports.tags = ["PriceFeedToken1","all"];
