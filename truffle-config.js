const HDWalletProvider = require('truffle-hdwallet-provider');
const fs = require('fs');

let rinkebyProvider, mumbaiProvider

try {
  const privateKey = fs.readFileSync(".secret").toString().trim();
  rinkebyProvider = new HDWalletProvider(privateKey, `https://rinkeby.infura.io/v3/ebebe0311e1e486eaa3cee22ec46f6fc`, 0, 1)
  mumbaiProvider = new HDWalletProvider(privateKey, `https://rpc-mumbai.matic.today`, 0, 1)
} catch (e) {
  console.log(e)
}


module.exports = {
  plugins: [
    "truffle-contract-size",
    'truffle-plugin-verify'],
  api_keys: {
    etherscan: 'QN3W816D9KHI2BHV38ZQMCVGDXR99A19H1'
  },
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },
    rinkeby: {
      networkCheckTimeout: 100000,
      provider: rinkebyProvider,
      network_id: 4,
      confirmations: 1,
      timeoutBlocks: 1000000000,
      gasLimit: 100000000,
    },
    mumbai: {
      networkCheckTimeout: 100000,
      provider: mumbaiProvider,
      network_id: 80001,
      confirmations: 5,
      timeoutBlocks: 200,
      skipDryRun: true
    },
  },
  contracts_directory: "./contracts/",
  contracts_build_directory: "./abi/",
  mocha: {
    reporter: "eth-gas-reporter",
    reporterOptions: {
      currency: "USD",
      gasPrice: 2,
    },
  },
  compilers: {
    solc: {
      version: '0.8.4',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
}