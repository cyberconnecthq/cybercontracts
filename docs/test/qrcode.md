# QRCode Library Fuzz Test

0. foundryup
```bash
foundryup
```

clean up
```bash
rm -rf ./test/qrcode ./misc/qrcode/html ./misc/qrcode/svg
```
1. Set desired test parameter (data length and iteration) in `./misc/qrcode/gen-sol.js` to generate solidity test files (300 is probably max)
2. Run

```bash
node misc/qrcode/gen-sol.js
```

3. Make sure you have `./misc/qrcode/svg` folder created.

```bash
mkdir -pv misc/qrcode/svg
```

4. Run

```bash
forge test --match-contract QRSVGIntegration -vvv
```

This runs QRSVG.sol against all generated input cases and write base64 encoded svg of the QRCode to `./misc/qrcode/svg`.

5. Run

```bash
node misc/qrcode/gen-html.js
```

This generates html files for each svg QRCode for verifying the content.

6. Run

```bash
node misc/qrcode/puppet.js
```

This runs a headless chrome for browser to read QRCode with Canvas and check if the content of QRCode is expected
