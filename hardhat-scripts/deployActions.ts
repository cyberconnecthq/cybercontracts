import assert from 'assert'
import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";
import { Interface } from 'ethers/lib/utils'
import { TransactionReceipt } from '@ethersproject/providers'

export const factoryAddress = '0x1bD54483A329861eB1b6d0F312Ab07F6Fd8a4000'; // GOERLI
export const factoryAbi = [
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "addr",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "bytes32",
        "name": "salt",
        "type": "bytes32"
      }
    ],
    "name": "Deployed",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "bytes",
        "name": "code",
        "type": "bytes"
      },
      {
        "internalType": "bytes32",
        "name": "salt",
        "type": "bytes32"
      }
    ],
    "name": "deploy",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]



async function main() {
  const factory = await ethers.getContractFactory("CyberEngine");
  const actionBytecode = factory.bytecode;
  const salt = 'CyberConnect';
  const computedAddr = getCreate2Address({
    salt,
    contractBytecode: actionBytecode,
    constructorTypes: [''],
    constructorArgs: [''],
  })

  console.log('Create2Address', computedAddr)
  console.log('Actions bytecode:', actionBytecode);

  const [signer, , ] = await ethers.getSigners();
  // const result = await deployCreate2Contract({
  //   salt,
  //   contractBytecode: actionBytecode,
  //   constructorTypes: [''],
  //   constructorArgs: [''],
  //   signer,
  // })

  // console.log('ContractAddress', result.address)

}

export async function deployContract(tx: any): Promise<Contract> {
  const result = await tx;
  await result.deployTransaction.wait();
  return result;
}

export async function deployCreate2Contract({
  salt,
  contractBytecode,
  constructorTypes = [] as string[],
  constructorArgs = [] as any[],
  signer,
}: {
  salt: string | number
  contractBytecode: string
  constructorTypes?: string[]
  constructorArgs?: any[]
  signer: Signer
}) {
  const saltHex = saltToHex(salt)

  const factory = new ethers.Contract(factoryAddress, factoryAbi, signer)

  const bytecode = buildBytecode(
    constructorTypes,
    constructorArgs,
    contractBytecode,
  )

  const result = await (await factory.deploy(bytecode, saltHex)).wait()

  const computedAddr = buildCreate2Address(saltHex, bytecode)

  const logs = parseEvents(result, factory.interface, 'Deployed')

  const addr = logs[0].args.addr.toLowerCase()
  assert.strictEqual(addr, computedAddr)

  return {
    txHash: result.transactionHash as string,
    address: addr as string,
    receipt: result as TransactionReceipt,
  }
}

export const buildBytecode = (
  constructorTypes: any[],
  constructorArgs: any[],
  contractBytecode: string,
) =>
  `${contractBytecode}`
  // `${contractBytecode}${encodeParams(constructorTypes, constructorArgs).slice(
  //   2,
  // )}`

export const buildCreate2Address = (saltHex: string, byteCode: string) => {
  return `0x${ethers.utils
    .keccak256(
      `0x${['ff', factoryAddress, saltHex, ethers.utils.keccak256(byteCode)]
        .map((x) => x.replace(/0x/, ''))
        .join('')}`,
    )
    .slice(-40)}`.toLowerCase()
}

export const saltToHex = (salt: string | number) => {
  salt = salt.toString()
  if(ethers.utils.isHexString(salt)){
    return salt
  }
  
  return ethers.utils.id(salt)
}

export const encodeParam = (dataType: any, data: any) => {
  const abiCoder = ethers.utils.defaultAbiCoder
  return abiCoder.encode([dataType], [data])
}

export const encodeParams = (dataTypes: any[], data: any[]) => {
  const abiCoder = ethers.utils.defaultAbiCoder
  return abiCoder.encode(dataTypes, data)
}

export const parseEvents = (
  receipt: TransactionReceipt,
  contractInterface: Interface,
  eventName: string,
) =>
  receipt.logs
    .map((log) => contractInterface.parseLog(log))
    .filter((log) => log.name === eventName)


export function getCreate2Address({
  salt,
  contractBytecode,
  constructorTypes = [] as string[],
  constructorArgs = [] as any[],
}: {
  salt: string | number
  contractBytecode: string
  constructorTypes?: string[]
  constructorArgs?: any[]
}) {
  return buildCreate2Address(
    saltToHex(salt),
    buildBytecode(constructorTypes, constructorArgs, contractBytecode),
  )
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
