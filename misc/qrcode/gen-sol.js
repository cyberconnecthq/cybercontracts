import * as fs from "fs/promises";
import * as path from "path";
const writeTemplate = async (i, batch) => {
  const file = await fs.readFile(
    path.join("./misc/qrcode", "QRSVG.t.sol.template"),
    "utf8"
  );
  const urls = batch.map((str) => `https://link3.to/${str}`);
  let out = file.replace(/URLS/g, JSON.stringify(urls));
  out = out.replace(/NAMES/g, JSON.stringify(batch));

  const output = path.join(dir, `QRSVG-${i}-${batch.length}.t.sol`);
  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(output, out);
  return { output, dir };
};

const dir = path.join("./test/qrcode/");

const main = async () => {
  try {
    const exists = await fs.access(dir, 0);
    if (exists) {
      await fs.rm(dir, { recursive: true, force: true });
    }
  } catch (err) {}
  const all = [];
  let batch = [];
  let counter = 0;
  const length = 27;
  const iteration = 100;
  let total = [];
  for (let j = 1; j <= length; j++) {
    // 27 is the max length of the link3 handle
    for (let i = 0; i < iteration; i++) {
      // how many tries for each length
      const str = randomString(j, wordlist);
      batch.push(str);
      if (batch.length == 40) {
        all.push(writeTemplate(counter, batch));
        total = total.concat(batch);
        batch = [];
        counter++;
      }
    }
  }
  if (batch) {
    all.push(writeTemplate(counter, batch));
    total = total.concat(batch);
  }
  const toFindDuplicates = (arry) =>
    arry.filter((item, index) => arry.indexOf(item) !== index);
  const duplicates = toFindDuplicates(total);
  console.log("random tests:", total.length);
  console.log("duplicate", duplicates.length);
  console.log("total unique tests", total.length - duplicates.length);
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
