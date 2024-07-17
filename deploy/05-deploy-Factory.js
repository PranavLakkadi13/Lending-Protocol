const { ethers, network } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    let Factory;

    log("--------------------------------------------------");
    log(`Deploying Factory  Contract ..................... `);
    Factory = await deploy("Factory", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });

    log("--------------------------------------------------");
    log("Factory Contract deployed at: " + (await Factory.address));
    log("--------------------------------------------------");
};

module.exports.tags = ["Factory"];
