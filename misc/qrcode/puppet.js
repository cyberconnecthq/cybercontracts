// const puppeteer = require('puppeteer');
import * as puppeteer from "puppeteer";
import * as path from "path";
import * as fs from "fs/promises";

(async () => {
  const files = await fs.readdir("./misc/qrcode/html");
  const browser = await puppeteer.launch();
  for (let i = 0; i < files.length; i++) {
    const page = await browser.newPage();
    const f = `file:${path.join(
      "/Users/ryanli/Documents/Code/cybercontracts/misc/qrcode/html",
      files[i]
    )}`;
    page.on("console", (msg) => {
      if (msg.text() + ".html" !== "https://link3.to/" + files[i]) {
        console.error(
          "====================wrong url. got, expected: ",
          msg.text(),
          files[i]
        );
      }
      console.log("Correct url:", msg.text());
    });
    await page.goto(f);
  }

  await browser.close();
})();
