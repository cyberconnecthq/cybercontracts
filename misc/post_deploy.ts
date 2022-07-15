import * as fs from "fs/promises";
import * as path from "path";

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
  await writeAbi();
};

main()
  .then(() => {})
  .catch((err) => {
    console.error(err);
  });
