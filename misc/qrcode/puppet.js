import * as path from "path";
import * as fs from "fs/promises";
import { Cluster } from "puppeteer-cluster";

(async () => {
  const cluster = await Cluster.launch({
    concurrency: Cluster.CONCURRENCY_CONTEXT,
    maxConcurrency: 20,
    // monitor: true,
  });
  const files = await fs.readdir("./misc/qrcode/html");
  console.log("total tests:", files.length);
  await cluster.task(async ({ page, data: url }) => {
    const file = path.parse(url).name;
    page.on("console", (msg) => {
      if (msg.text() !== "https://link3.to/" + file) {
        console.error(
          "====================wrong url. got, expected: ",
          msg.text(),
          file
        );
      } else {
        // console.log("Correct url:", msg.text());
      }
    });
    await page.goto(url);
  });
  for (let i = 0; i < files.length; i++) {
    const f = `file:${path.join(
      "/Users/ryanli/Documents/Code/cybercontracts/misc/qrcode/html",
      files[i]
    )}`;
    cluster.queue(f);
  }

  await cluster.idle();
  await cluster.close();
})();
