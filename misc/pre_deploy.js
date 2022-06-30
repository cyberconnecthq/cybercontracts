import * as fsSync from "fs";
import * as fs from "fs/promises";
import * as dotenv from "dotenv";
import * as path from "path";
dotenv.config({ debug: true, path: ".env.rinkeby" });

import { default as FormData } from "form-data";
import axios from "axios";

import { ethers } from "ethers";

const pinataBase = "https://cyberconnect.mypinata.cloud/ipfs/";
const pinataJWT = process.env.PINATA_JWT;

const writeTemplate = async (profileProxy) => {
  const file = await fs.readFile(path.join("./template", "index.html"), "utf8");
  const out = file.replace(
    /0x000000000000000000000000000000000000DEAD/g,
    profileProxy
  );
  const dir = path.join("./docs/template");
  await fs.rm(dir, { recursive: true, force: true });

  const output = path.join(dir, "index.html");
  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(output, out);
  return { output, dir };
};
const writeToPinata = async ({ output, dir }) => {
  var data = new FormData();
  data.append("file", fsSync.createReadStream(output));
  data.append("pinataOptions", '{"cidVersion": 1}');

  const config = {
    method: "post",
    url: "https://api.pinata.cloud/pinning/pinFileToIPFS",
    headers: {
      Authorization: "Bearer " + pinataJWT,
      ...data.getHeaders(),
    },
    data: data,
  };

  const res = await axios(config);
  console.log(res.data);

  await fs.rename(output, path.join(dir, res.data.IpfsHash));
  return pinataBase + res.data.IpfsHash;
};

const calc = async () => {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.RINKEBY_RPC_URL
  );
  const deployer = new ethers.Wallet(process.env.PRIVATE_KEY);

  let deployerNonce = await provider.getTransactionCount(deployer.address);
  const profileProxyNonce = ethers.utils.hexlify(deployerNonce + 3);
  const profileProxyAddr =
    "0x" +
    ethers.utils
      .keccak256(ethers.utils.RLP.encode([deployer.address, profileProxyNonce]))
      .substr(26);
  return ethers.utils.getAddress(profileProxyAddr); // checksum
};

const templateDeployScript = async (profileProxy, templateURL) => {
  console.log(templateURL);
  const p = path.join("./template", "Deploy.s.sol.template");
  const outP = path.join("./script", "Deploy.s.sol");
  const file = await fs.readFile(p, "utf8");
  let out = file.replace(/0xDEAD/g, profileProxy);
  out = out.replace(/TEMPLATE_URL/g, templateURL);
  await fs.writeFile(outP, out);
};

const main = async () => {
  const profileProxy = await calc();
  const out = await writeTemplate(profileProxy);
  const pinataURL = await writeToPinata(out);
  console.log("profileProxy", profileProxy);
  await templateDeployScript(profileProxy, pinataURL);
};

main()
  .then(() => {})
  .catch((err) => {
    console.error(err);
  });
