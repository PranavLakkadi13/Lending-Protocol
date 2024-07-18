const { ethers, network } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    let Router;

    const LendTokens = await deployments.get("LendTokens");
    const Token1 = await deployments.get("Token1");
    const Token2 = await deployments.get("Token2");
    const PriceFeed1 = await deployments.get("PriceFeedToken1");
    const PriceFeed2 = await deployments.get("PriceFeedToken2");
    const Factory = await deployments.get("Factory");

    const priceFeedTokens = [PriceFeed1.address, PriceFeed2.address];
    const tokens = [Token1.address, Token2.address];

    const args = [Factory.address, tokens, priceFeedTokens, LendTokens.address];

    log("--------------------------------------------------");
    log(`Deploying Router Contract ..................... `);
    Router = await deploy("Router", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });

    log("--------------------------------------------------");
    log("Router Contract deployed at: " + (await Router.address));
    log("--------------------------------------------------");
};

module.exports.tags = ["Router"];
