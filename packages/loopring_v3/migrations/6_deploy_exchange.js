// Deploy the ExchangeV3Deployer library which is very large in terms of
// gas usage. We need to deploy most libraries linked from it as stand-alone
// libraries, otherwise we'll run into the 'exceeded block gas limit' issue.

var LRCToken = artifacts.require("./test/tokens/LRC.sol");
var WETHToken = artifacts.require("./test/tokens/WETH.sol");
var ExchangeAccounts = artifacts.require("./impl/libexchange/ExchangeAccounts");
var ExchangeAdmins = artifacts.require("./impl/libexchange/ExchangeAdmins");
var ExchangeBalances = artifacts.require("./impl/libexchange/ExchangeBalances");
var ExchangeBlocks = artifacts.require("./impl/libexchange/ExchangeBlocks");
var ExchangeData = artifacts.require("./impl/libexchange/ExchangeData");
var ExchangeDeposits = artifacts.require("./impl/libexchange/ExchangeDeposits");
var ExchangeGenesis = artifacts.require("./impl/libexchange/ExchangeGenesis");
var ExchangeMode = artifacts.require("./impl/libexchange/ExchangeMode");
var ExchangeTokens = artifacts.require("./impl/libexchange/ExchangeTokens");
var ExchangeWithdrawals = artifacts.require(
  "./impl/libexchange/ExchangeWithdrawals"
);
var ExchangeV3Deployer = artifacts.require("./impl/ExchangeV3Deployer");

module.exports = function(deployer, network, accounts) {
  if (network === "live") {
    // ignore.
  } else {
    deployer
      .then(() => {
        return Promise.all([LRCToken.deployed(), WETHToken.deployed()]);
      })
      .then(() => {
        return Promise.all([
          deployer.deploy(ExchangeData),
          deployer.deploy(ExchangeBalances)
        ]);
      })
      .then(() => {
        return Promise.all([
          deployer.link(ExchangeData, [
            ExchangeAccounts,
            ExchangeAdmins,
            ExchangeBlocks,
            ExchangeDeposits,
            ExchangeGenesis,
            ExchangeMode,
            ExchangeTokens,
            ExchangeWithdrawals
          ])
        ]);
      })
      .then(() => {
        return Promise.all([
          deployer.link(ExchangeBalances, [
            ExchangeAccounts,
            ExchangeWithdrawals
          ])
        ]);
      })
      .then(() => {
        return Promise.all([
          deployer.deploy(ExchangeMode),
          deployer.deploy(ExchangeAccounts)
        ]);
      })
      .then(() => {
        return Promise.all([
          deployer.link(ExchangeMode, [
            ExchangeAdmins,
            ExchangeBlocks,
            ExchangeDeposits,
            ExchangeTokens,
            ExchangeWithdrawals
          ]),
          deployer.link(ExchangeAccounts, [
            ExchangeDeposits,
            ExchangeGenesis,
            ExchangeWithdrawals
          ])
        ]);
      })
      .then(() => {
        return Promise.all([
          deployer.deploy(ExchangeAdmins),
          deployer.deploy(ExchangeBlocks),
          deployer.deploy(ExchangeTokens)
        ]);
      })
      .then(() => {
        return Promise.all([
          deployer.link(ExchangeTokens, [
            ExchangeDeposits,
            ExchangeGenesis,
            ExchangeWithdrawals
          ])
        ]);
      })
      .then(() => {
        return Promise.all([
          deployer.deploy(ExchangeGenesis),
          deployer.deploy(ExchangeDeposits),
          deployer.deploy(ExchangeWithdrawals)
        ]);
      })
      .then(() => {
        return Promise.all([
          deployer.link(ExchangeData, ExchangeV3Deployer),
          deployer.link(ExchangeBalances, ExchangeV3Deployer),
          deployer.link(ExchangeMode, ExchangeV3Deployer),
          deployer.link(ExchangeAccounts, ExchangeV3Deployer),
          deployer.link(ExchangeAdmins, ExchangeV3Deployer),
          deployer.link(ExchangeBlocks, ExchangeV3Deployer),
          deployer.link(ExchangeTokens, ExchangeV3Deployer),
          deployer.link(ExchangeGenesis, ExchangeV3Deployer),
          deployer.link(ExchangeDeposits, ExchangeV3Deployer),
          deployer.link(ExchangeWithdrawals, ExchangeV3Deployer)
        ]);
      })
      .then(() => {
        console.log(">>>>>>>> Deployed contracts addresses (deploy_exchange):");
        console.log("ExchangeData: ", ExchangeData.address);
        console.log("ExchangeBalances: ", ExchangeBalances.address);
        console.log("ExchangeMode: ", ExchangeMode.address);
        console.log("ExchangeAccounts: ", ExchangeAccounts.address);
        console.log("ExchangeAdmins: ", ExchangeAdmins.address);
        console.log("ExchangeBlocks: ", ExchangeBlocks.address);
        console.log("ExchangeTokens: ", ExchangeTokens.address);
        console.log("ExchangeGenesis: ", ExchangeGenesis.address);
        console.log("ExchangeDeposits: ", ExchangeDeposits.address);
        console.log("ExchangeWithdrawals: ", ExchangeWithdrawals.address);
      })
      .then(() => {
        return Promise.all([
          deployer.deploy(ExchangeV3Deployer, { gas: 6700000 })
        ]);
      })
      .then(() => {
        console.log("WETHToken:", WETHToken.address);
        console.log("LRCToken:", LRCToken.address);
        console.log("ExchangeV3Deployer:", ExchangeV3Deployer.address);
        console.log("");
      });
  }
};