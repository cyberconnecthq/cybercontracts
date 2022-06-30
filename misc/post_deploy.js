import * as fs from "fs/promises";
import * as path from "path";
import { markdownTable } from "markdown-table";

const base = "./broadcast/Deploy.s.sol";
const writeDeploy = async () => {
  const folders = await fs.readdir(base);
  for (let i = 0; i < folders.length; i++) {
    const chainId = folders[i];
    let chain = "";
    let etherscan = "";
    switch (chainId) {
      case "1":
        chain = "mainnet";
        etherscan = "https://etherscan.io/address/";
        break;
      case "4":
        chain = "rinkeby";
        etherscan = "https://rinkeby.etherscan.io/address/";
        break;
      case "31337":
        chain = "local";
        break;
    }
    const file = await fs.readFile(
      path.join(base, chainId, "run-latest.json"),
      "utf8"
    );
    const txs = JSON.parse(file);
    const rst = txs.transactions.map((tx) => tx.contractAddress);
    const md = markdownTable([
      ["Contract", "Address", "Etherscan"],
      ["Roles", rst[0], etherscan + rst[0]],
      ["CyberEngine (Impl)", rst[1], etherscan + rst[1]],
      ["ProfileNFT (Impl)", rst[2], etherscan + rst[2]],
      ["ProfileNFT (Proxy)", rst[3], etherscan + rst[3]],
      ["BoxNFT (Impl)", rst[4], etherscan + rst[4]],
      ["BoxNFT (Proxy)", rst[5], etherscan + rst[5]],
      ["SubscribeNFT (Impl)", rst[6], etherscan + rst[6]],
      ["SubscribeNFT (Beacon)", rst[7], etherscan + rst[7]],
      ["CyberEngine (Proxy)", rst[8], etherscan + rst[8]],
    ]);
    await fs.writeFile(path.join("./docs/deploy", chain + ".md"), md);
  }
};

const writeAbi = async () => {
  const folders = [
    "BoxNFT.sol/BoxNFT.json",
    "SubscribeNFT.sol/SubscribeNFT.json",
    "ProfileNFT.sol/ProfileNFT.json",
    "CyberEngine.sol/CyberEngine.json",
    "Roles.sol/Roles.json",
  ];
  const ps = folders.map(async (file) => {
    const f = await fs.readFile(path.join("./out", file), "utf8");
    const json = JSON.parse(f);
    return fs.writeFile(path.join("docs/abi", file), JSON.stringify(json.abi));
  });
  await Promise.all(ps);
};

const main = async () => {
  await writeDeploy();
  await writeAbi();
};

main()
  .then(() => {})
  .catch((err) => {
    console.error(err);
  });
