import fs from "fs";
import "hardhat-preprocessor";
import "hardhat-contract-sizer";
import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
//require("dotenv").config({ path: __dirname + "/.env.goerli" });
require("dotenv").config({ path: __dirname + "/.env.bnbt" });

/** @type import('hardhat/config').HardhatUserConfig */
const config: HardhatUserConfig = {
  networks: {
    hardhat: {},
    // goerli: {
    //   url: process.env.GOERLI_RPC_URL,
    //   accounts: [process.env.PRIVATE_KEY as string],
    // },
    bnbt: {
      url: process.env.BNBT_RPC_URL,
      accounts: [process.env.PRIVATE_KEY as string],
    },
  },
  solidity: {
    version: "0.8.14",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  preprocess: {
    eachLine: (hre: any) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            // this matches all occurrences not just the start of import which could be a problem
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
  paths: {
    sources: "./src",
    cache: "./cache_hardhat",
  },
};
function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split("="));
}
export default config;
