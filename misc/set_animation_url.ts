import * as fs from "fs/promises";
import * as dotenv from "dotenv";
import * as path from "path";
import * as fsSync from "fs";
import { default as FormData } from "form-data";
import axios from "axios";
import { ethers } from "ethers";
import * as JSON5 from "json5";

dotenv.config({ debug: true, path: ".env.pinata" });

const base = "docs/deploy";
const pinataBase = "https://cyberconnect.mypinata.cloud/ipfs/";
const pinataJWT = process.env.PINATA_JWT;

const getLink3Profile = async (chainName: string) => {
  const file = path.join(base, chainName, "contract.json");
  const data = await fs.readFile(file, "utf-8");
  const j = JSON5.parse(data);
  return {
    link3: ethers.utils.getAddress(j["Link3 Profile"]),
    link3Auth: ethers.utils.getAddress(j["Link3 Authority"]),
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
  chainName: string,
  link3Auth: string
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
  out = out.replace(/LINK3_AUTH/g, link3Auth);
  await fs.writeFile(outP, out);
};

const main = async (chainName: string) => {
  const { link3, link3Auth } = await getLink3Profile(chainName);
  const out = await writeTemplate(link3, chainName);
  const pinataURL = await writeToPinata(out);
  console.log("link3", link3);
  console.log("link3 auth", link3Auth);
  console.log("pinataURL", pinataURL);
  await templateDeployScript(link3, pinataURL, chainName, link3Auth);
};

main(process.argv[2])
  .then(() => {})
  .catch((err) => {
    console.error(err);
  });
