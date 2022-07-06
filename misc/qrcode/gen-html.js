import * as fs from "fs/promises";
import * as path from "path";
const writeTemplate = async (url, content) => {
  const file = await fs.readFile(
    path.join("./misc/qrcode/", "qr-test.html.template"),
    "utf8"
  );
  const out = file.replace(/REPLACE_ME/g, content);
  const dir = path.join("./misc/qrcode/html/");
  await fs.rm(dir, { recursive: true, force: true });

  const output = path.join(dir, `${url}.html`);
  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(output, out);
  return { output, dir };
};

const p = "./misc/qrcode/svg";

const main = async () => {
  const files = await fs.readdir(p);
  console.log(files);
  const all = [];
  const a = async (aa) => {
    const content = await fs.readFile(path.join(p, aa));
    return writeTemplate(aa, content);
  };
  for (let i = 0; i < files.length; i++) {
    all.push(a(files[i]));
  }
  return Promise.all(all);
};

main()
  .then(() => {})
  .catch((err) => {
    console.error(err);
  });
