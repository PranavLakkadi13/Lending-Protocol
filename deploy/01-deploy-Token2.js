const { ethers, network } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  let token2;

  log("--------------------------------------------------");
  log(`2. Deploying Token1 ..................... `);
  token2 = await deploy("Token2", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  log("--------------------------------------------------");
  log("Token2 deployed at: " + (await token2.address));
  log("--------------------------------------------------");
};

module.exports.tags = ["Token2"];
