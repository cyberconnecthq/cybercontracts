import * as fs from "fs/promises";
import * as dotenv from "dotenv";
import * as path from "path";
import * as fsSync from "fs";
import { default as FormData } from "form-data";
import axios from "axios";
import { ethers } from "ethers";

dotenv.config({ debug: true, path: ".env.pinata" });

const base = "docs/deploy";
const pinataBase = "https://cyberconnect.mypinata.cloud/ipfs/";
const pinataJWT = process.env.PINATA_JWT;

const getLink3Profile = async (chainName: string) => {
  const file = path.join(base, chainName, "contract.md");
  const data = await fs.readFile(file, "utf-8");
  let matched = data.match(/\|Link3 Profile\|(.*)\|/);
  return {
    link3: ethers.utils.getAddress(matched![1]),
  };
};

const writeTemplate = async (profileProxy: string, chainName: string) => {
  const chain = chainName.split("-")[0];

  const file = await fs.readFile(path.join("./template", "index.html"), "utf8");
  let out = file.replace(
    /0x000000000000000000000000000000000000DEAD/g,
    profileProxy
  );
  out = out.replace(/_SOME_NETWORK_/g, chain);
  const dir = path.join("./docs/template", chainName);
  await fs.rm(dir, { recursive: true, force: true });

  const output = path.join(dir, "index.html");
  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(output, out);
  return { output, dir };
};
const writeToPinata = async ({
  output,
  dir,
}: {
  output: string;
  dir: string;
}) => {
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
const templateDeployScript = async (
  link3Profile: string,
  templateURL: string,
  chainName: string
) => {
  const p = path.join(
    "./script/animation_url/",
    chainName,
    "SetAnimationURL.s.sol.template"
  );
  const outP = path.join(
    "./script/animation_url/",
    chainName,
    "SetAnimationURL.s.sol"
  );
  const file = await fs.readFile(p, "utf8");
  let out = file.replace(/LINK3_PROFILE/g, link3Profile);
  out = out.replace(/ANIMATION_URL/g, templateURL);
  await fs.writeFile(outP, out);
};

const main = async (chainName: string) => {
  const { link3 } = await getLink3Profile(chainName);
  const out = await writeTemplate(link3, chainName);
  const pinataURL = await writeToPinata(out);
  console.log("link3", link3);
  console.log("pinataURL", pinataURL);
  await templateDeployScript(link3, pinataURL, chainName);
};

main(process.argv[2])
  .then(() => {})
  .catch((err) => {
    console.error(err);
  });
