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
      ["RolesAuthority", rst[1], etherscan + rst[1]],
      ["CyberEngine (Impl)", rst[2], etherscan + rst[2]],
      ["CyberEngine (Proxy)", rst[3], etherscan + rst[3]],
      ["Link3 Descriptor (Impl)", rst[4], etherscan + rst[3]],
      ["Link3 Descriptor (Proxy)", rst[5], etherscan + rst[4]],

      ["Essence Factory", rst[10], etherscan + rst[10]],
      ["Subscribe Factory", rst[11], etherscan + rst[11]],
      ["Profile Factory", rst[12], etherscan + rst[12]],
      ["Link3 Profile (Proxy)", rst[13], etherscan + rst[13]],
      ["Cyber Treasury", rst[14], etherscan + rst[14]],
      [
        "Link3 Profile MW (PermissionedFeeCreationMw)",
        rst[15],
        etherscan + rst[15],
      ],
      ["CyberBoxNFT (Impl)", rst[18], etherscan + rst[18]],
      ["CyberBoxNFT (Proxy)", rst[19], etherscan + rst[19]],
    ]);
    await fs.writeFile(path.join("./docs/deploy", chain + ".md"), md);
  }
};

const writeAbi = async () => {
  const folders = [
    "RolesAuthority.sol/RolesAuthority.json",
    "CyberEngine.sol/CyberEngine.json",
    "Link3ProfileDescriptor.sol/Link3ProfileDescriptor.json",
    "ProfileNFT.sol/ProfileNFT.json",
    "Treasury.sol/Treasury.json",
    "PermissionedFeeCreationMw.sol/PermissionedFeeCreationMw.json",
    "CyberBoxNFT.sol/CyberBoxNFT.json",
    "SubscribeNFT.sol/SubscribeNFT.json",
    "EssenceNFT.sol/EssenceNFT.json",
  ];
  const ps = folders.map(async (file) => {
    const f = await fs.readFile(path.join("./out", file), "utf8");
    const json = JSON.parse(f);
    const fileName = path.parse(file).name;
    return fs.writeFile(
      path.join("docs/abi", `${fileName}.json`),
      JSON.stringify(json.abi)
    );
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
