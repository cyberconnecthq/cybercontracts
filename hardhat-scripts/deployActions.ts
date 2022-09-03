import { ethers } from "hardhat";
import { Contract } from "ethers";

async function main() {
  const factory = await ethers.getContractFactory("Actions");
  const publishingLogic = await deployContract(factory.deploy());
  console.log(publishingLogic);
}

export async function deployContract(tx: any): Promise<Contract> {
  const result = await tx;
  await result.deployTransaction.wait();
  return result;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
