import * as fs from "fs/promises";
import * as path from "path";
const writeTemplate = async (length, url) => {
  const file = await fs.readFile(
    path.join("./misc/qrcode", "QRSVG.t.sol.template"),
    "utf8"
  );
  let out = file.replace(/REPLACE_ME/g, "https://link3.to/" + url);
  out = out.replace(/NAME/g, url);
  const dir = path.join("./test/qrcode/");
  await fs.rm(dir, { recursive: true, force: true });

  const output = path.join(dir, `QRSVG-${length}-${url}.t.sol`);
  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(output, out);
  return { output, dir };
};

const main = async () => {
  // TODO: make sure to include all characters
  const all = [];
  for (let j = 1; j <= 27; j++) { // 27 is the max length of the link3 handle
    for (let i = 0; i < 1; i++) { // how many tries for each length
      const str = randomString(j, wordlist);
      all.push(writeTemplate(j, str));
    }
  }
  return Promise.all(all);
};
function randomString(length, chars) {
  var result = "";
  for (var i = length; i > 0; --i)
    result += chars[Math.floor(Math.random() * chars.length)];
  return result;
}
const wordlist = "0123456789abcdefghijklmnopqrstuvwxyz_";

main()
  .then(() => {})
  .catch((err) => {
    console.error(err);
  });
