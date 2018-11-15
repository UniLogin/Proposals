# Amber airdorp script

Script for sending small amounts of tokens to list of addreses.

## Usage on etherscan

Get list of addresses, e.g. go to `https://etherscan.io/token/OmiseGo#balances` and in web dev console type:
Address for WTC: `https://etherscan.io/token/0xb7cb1c96db6b22b0d3d9536e0108d062bd488f74#balances`

```
$(".table-responsive tr td:nth-child(2) span a").map((i, e) => $(e).text()).toArray().join("\", \n\"")
```

Add results to ```script/send.js``` and configure the file (token address, your address). To start run in command line:

## Usage on ethplorer.io
Example link:
`https://ethplorer.io/address/0xb7cb1c96db6b22b0d3d9536e0108d062bd488f74#tab=tab-holders&pageSize=1000`

Example query:
```
$("#token-holders-tab .table tr td:nth-child(2) a").map((i, e) => $(e).text()).toArray().join("\", \n\"")
```

```bash
npm run send
```

btw run parity in unlock mode to avoid repetitive password typing.
Script is synchronous, so it is slow, but avoids congestion generation.

Viola!

## Instalation

```bash
npm install
```

## Testing
You should have running TestRPC
```bash
npm test
```
# Proposals
