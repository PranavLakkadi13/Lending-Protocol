const { deployments,ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(
        "Deploying the contracts with the account:",
        deployer.address
    );
    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Token1 = await ethers.getContractAt("Token1","0x986ca47AeCc2a5d54dBfAC40254701EDF440f173",deployer);
    const Token2 = await ethers.getContractAt("Token2","0xf8d1f181e52B941309B5E3b9B36769B64335aE7d",deployer);

    const Token1BalanceCheck = await Token1.balanceOf(deployer.address);
    console.log("Balance of deployer:", Token1BalanceCheck.toString());
    await Token1.transfer(Token2.address,1000);

    const Token2BalanceCheck = await Token2.balanceOf(deployer.address);
    console.log("Balance of deployer:", Token2BalanceCheck.toString());

    console.log("Token Contracts Loaded successfully!!!!")
    console.log("-------------------------------------------------------------------------------------------------");
    console.log("-------------------------------------------------------------------------------------------------");

    const PriceFeedContractToken1 = await ethers.getContractAt("PriceFeedToken1","0xF132c32539d2E27E18eC34C3a113489a26687Fa9",deployer);
    const PriceFeedContractToken2 = await ethers.getContractAt("PriceFeedToken2","0xC8B50567e39315CE041BfCE2911731245b275aF1",deployer);

    const LatestPriceOfToken1 = await PriceFeedContractToken1.latestRoundData();
    console.log("Latest Price of Token1:", LatestPriceOfToken1.toString());

    console.log("Price Feed Contracts Loaded successfully!!!!")
    console.log("-------------------------------------------------------------------------------------------------");
    console.log("-------------------------------------------------------------------------------------------------");


    const Factory = await ethers.getContractAt("Factory","0x79CA6e5496c8807c80AeF5D67520933fc7af72aB",deployer);
    const poolAddress = await Factory.getPoolAddress(Token1.address);
    console.log("Pair Address:",poolAddress);

    console.log("Factory Contracts Loaded successfully!!!!")
    console.log("-------------------------------------------------------------------------------------------------");
    console.log("-------------------------------------------------------------------------------------------------");


    const lendTokens = await ethers.getContractAt("LendTokens","0xceE69dC06aF4b9F5a8622FB8de4bd4678e1Fd2F7",deployer);
    console.log("LendToken Contracts Loaded successfully!!!!")
    console.log("-------------------------------------------------------------------------------------------------");
    console.log("-------------------------------------------------------------------------------------------------");


}

main().then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });