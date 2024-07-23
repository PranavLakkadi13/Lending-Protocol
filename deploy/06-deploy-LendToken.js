const { ethers, network } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    let LendTokens;

    log("--------------------------------------------------");
    log(`Deploying LendTokens Contract ..................... `);
    LendTokens = await deploy("LendTokens", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });

    log("--------------------------------------------------");
    log("LendToken Contract deployed at: " + (await LendTokens.address));
    log("--------------------------------------------------");
};

module.exports.tags = ["LendTokens","all"];
