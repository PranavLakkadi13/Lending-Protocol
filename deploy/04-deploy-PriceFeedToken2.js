const { ethers, network } = require("hardhat");
const { Token2Args } = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  let PriceFeedToken2;

  log("--------------------------------------------------");
  log(`4. Deploying PriceFeedToken2 Contract ..................... `);
  PriceFeedToken2 = await deploy("PriceFeedToken2", {
    from: deployer,
    args: [Token2Args[0], Token2Args[1]],
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  log("--------------------------------------------------");
  log(
    "PriceFeedToken2 Contract deployed at: " + (await PriceFeedToken2.address)
  );
  log("--------------------------------------------------");
};

module.exports.tags = ["PriceFeedToken2","all"];
