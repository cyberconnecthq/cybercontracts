import { ethers } from "hardhat";

async function main() {
  const salt = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("CyberConnect"));
  console.log("salt", salt);
  // goerli
  const create2Deployer = await ethers.getContractAt(
    "Create2Deployer",
    // "0xeE048722AE9F11EFE0E233c9a53f2CaD141acF51" // goerli
    "0x4077B8554A5F9A3C2D10c6Bb467B7E26Caf65ad9" // bnbt
  );
  const creationCode = (
    await ethers.getContractFactory("ProfileDeployer", {
      libraries: {
        // Actions: "0x26d74f09dc17b6239310aa27c213394acb2ae0ca", // goerli
        Actions: "0x06944d76ba21c4b77d3b5261058617c9d949a888", // bnbt
      },
    })
  ).bytecode;
  console.log("creationCode", creationCode);
  // const rst = await (
  const tx = await create2Deployer.deploy(creationCode, salt, {
    gasLimit: 30000000,
    // gasPrice: 2000000000,
  });
  const receipt = await tx.wait();
  console.log(receipt);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
