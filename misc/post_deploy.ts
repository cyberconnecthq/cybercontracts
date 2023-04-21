import * as fs from "fs/promises";
import * as path from "path";

const writeAbi = async () => {
  const folders = [
    "RolesAuthority.sol/RolesAuthority.json",
    "CyberEngine.sol/CyberEngine.json",
    "EssenceNFT.sol/EssenceNFT.json",
    "ProfileNFT.sol/ProfileNFT.json",
    "SubscribeNFT.sol/SubscribeNFT.json",

    "Link3ProfileDescriptor.sol/Link3ProfileDescriptor.json",
    "CyberBoxNFT.sol/CyberBoxNFT.json",
    "CyberGrandNFT.sol/CyberGrandNFT.json",
    "MBNFT.sol/MBNFT.json",
    "FrameNFT.sol/FrameNFT.json",
    "MiniShardNFT.sol/MiniShardNFT.json",
    "CyberVault.sol/CyberVault.json",
    "RelationshipChecker.sol/RelationshipChecker.json",

    "Treasury.sol/Treasury.json",

    "CollectDisallowedMw.sol/CollectDisallowedMw.json",
    "CollectMerkleDropMw.sol/CollectMerkleDropMw.json",
    "CollectOnlySubscribedMw.sol/CollectOnlySubscribedMw.json",
    "CollectPaidMw.sol/CollectPaidMw.json",
    "CollectPermissionMw.sol/CollectPermissionMw.json",
    "CollectLimitedTimePaidMw.sol/CollectLimitedTimePaidMw.json",
    "CollectPermissionPaidMw.sol/CollectPermissionPaidMw.json",
    "CollectFlexPaidMw.sol/CollectFlexPaidMw.json",

    "PermissionedFeeCreationMw.sol/PermissionedFeeCreationMw.json",
    "StableFeeCreationMw.sol/StableFeeCreationMw.json",
    "SubscribeDisallowedMw.sol/SubscribeDisallowedMw.json",
    "SubscribeOnlyOnceMw.sol/SubscribeOnlyOnceMw.json",
    "SubscribePaidMw.sol/SubscribePaidMw.json",
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
