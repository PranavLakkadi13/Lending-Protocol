/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
// require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
// require("@nomicfoundation/hardhat-verify");
require("hardhat-deploy");
require("solidity-coverage");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
require("dotenv").config();

const RPC_URL_Alchemy_SEPOLIA = process.env.RPC_URL_Alchemy_SEPOLIA;
const Private_Key = process.env.Private_Key;
const RPC_URL_POLYGON = process.env.RPC_URL_POLYGON;
const PolygonScan_API_KEY = process.env.PolygonScan_API_KEY;
const Etherscan_API_KEY = process.env.Etherscan_API_KEY;
const Coinmarketcap_API_KEY = process.env.Coinmarketcap_API_KEY;
const RPC_URL_Alchemy_MAINNET = process.env.RPC_URL_Alchemy_MAINNET;
const RPC_URL_Dojima_Testnet = process.env.RPC_URL_Dojima_Testnet;

const Private_Key_G = process.env.Private_Key_G;
const RPC_URL_G = process.env.RPC_URL_G;

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
      blockConfirmations: 1,
      // forking: {
      //   url: RPC_URL_Alchemy_MAINNET,
      // },
    },
    sepolia: {
      url: RPC_URL_Alchemy_SEPOLIA,
      accounts: [Private_Key],
      chainId: 11155111,
      blockConfirmations: 6,
    },
    polygon: {
      url: RPC_URL_POLYGON,
      accounts: [Private_Key],
      chainId: 80002,
      blockConfirmations: 6,
    },
    dojima : {
      url: RPC_URL_Dojima_Testnet,
      accounts: [Private_Key],
      chainId: 184,
      blockConfirmations: 6,
    }
  },
  solidity: {
    compilers: [
      { version: "0.4.19" },
      { version: "0.8.20" },
      { version: "0.6.6" },
    ],
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    player: {
      default: 1,
    },
  },
  // etherscan: {
  //   apiKey: Etherscan_API_KEY,
  //   customChains: [
  //     {
  //       network: "sepolia",
  //       chainId: 11155111,
  //       urls: {
  //         apiURL: "https://api-sepolia.etherscan.io/api",
  //         browserURL: "https://sepolia.etherscan.io",
  //       },
  //     },
  //   ],
  // },
  etherscan : {
    apikey: {
      dojima : "",
    },
    customChains: [
      {
        network: "dojima",
        chainId: 184,
        urls : {
          apiURL: "https://api-explorer-test.dojima.network/api",
          browserURL: "https://explorer-test.dojima.network/",
        }
      }
    ]
  },
  // polygonscan: {
  //   apiKey: PolygonScan_API_KEY,
  // },
  gasReporter: {
    enabled: true,
    outputFile: "gas-reporter.txt",
    noColors: true,
    currency: "USD",
    coinmarketcap: Coinmarketcap_API_KEY,
    token: "ETH",
  },
  mocha: {
    timeout: 1000000,
  },
};
