require("dotenv").config();
const HDWalletProvider = require("truffle-hdwallet-provider");
const PrivateKeyProvider = require("truffle-privatekey-provider");

// Please config the following env variables in `.env`` as follows:
//```
//ETHERSCAN_API_KEY=<YOUR_KEY>
//INFURA_PROJECT_ID=<YOUR_PROJECT_ID>
//WALLET_PRIVATE_KEY=<YOUR_PRIVATE_KEY>
//WALLET_MNEMONIC=<YOUR_MNEMONIC>
//```
//
// OR in command line add something like this:
//     `DOTENV_CONFIG_ETHERSCAN_API_KEY=value npm run mycommand`

const getWalletProvider = function(network) {
  if (process.env.INFURA_PROJECT_ID == "") {
    console.log(process.env);
    console.error(">>>> ERROR: INFURA_PROJECT_ID is missing !!!");
    return;
  }
  var infuraAPI =
    "https://" + network + ".infura.io/v3/" + process.env.INFURA_PROJECT_ID;

  var provider;
  if (process.env.WALLET_PRIVATE_KEY != "") {
    provider = new PrivateKeyProvider(
      process.env.WALLET_PRIVATE_KEY,
      infuraAPI
    );
  } else if (process.env.WALLET_MNEMONIC != "") {
    provider = new HDWalletProvider(process.env.WALLET_MNEMONIC, infuraAPI);
  } else {
    console.log(process.env);
    console.error(
      ">>>> ERROR: WALLET_PRIVATE_KEY or WALLET_MNEMONIC has to be set !!!"
    );
    return;
  }
  return provider;
};

module.exports = {
  compilers: {
    solc: {
      settings: {
        optimizer: {
          enabled: true,
          runs: 100
        }
      },
      version: "0.5.10"
    }
  },
  plugins: ["truffle-plugin-verify"],
  api_keys: {
    etherscan: `process.env.ETHERSCAN_API_KEY`
  },
  networks: {
    live: {
      // provider: function() {
      //   return getWalletProvider("mainnet");
      // },
      network_id: "1", // main-net
      gasPrice: 5000000000
    },
    testnet: {
      host: "localhost",
      port: 8545,
      network_id: "2", // main-net
      gasPrice: 21000000000
    },
    ropsten: {
      // This will actually deploy to Infura's ropsten-fork chain, so
      // txs won't be available on https://ropsten.etherscan.io
      network_id: 3,
      provider: function() {
        return getWalletProvider("ropsten");
      },
      gasPrice: 1000000000,
      gas: 6700000
    },
    rinkeby: {
      network_id: 4,
      provider: function() {
        return getWalletProvider("rinkeby");
      },
      gasPrice: 1000000000,
      gas: 6700000
    },
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*",
      gasPrice: 21000000000,
      gas: 6700000
    },
    coverage: {
      host: "localhost",
      network_id: "*",
      port: 8555, // <-- If you change this, also set the port option in .solcover.js.
      gas: 0xfffffffffff, // <-- Use this high gas value
      gasPrice: 0x01 // <-- Use this low gas price
    },
    docker: {
      host: "ganache",
      port: 8545,
      network_id: "*",
      gasPrice: 21000000000,
      gas: 6700000
    }
  },
  test_directory: "transpiled/test",
  migrations_directory: "transpiled/migrations"
};
