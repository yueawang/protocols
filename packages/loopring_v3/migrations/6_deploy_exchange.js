// Deploy the ExchangeV3 library which is very large in terms of
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
var ExchangeV3 = artifacts.require("./impl/ExchangeV3");

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
          deployer.link(ExchangeData, ExchangeV3),
          deployer.link(ExchangeBalances, ExchangeV3),
          deployer.link(ExchangeMode, ExchangeV3),
          deployer.link(ExchangeAccounts, ExchangeV3),
          deployer.link(ExchangeAdmins, ExchangeV3),
          deployer.link(ExchangeBlocks, ExchangeV3),
          deployer.link(ExchangeTokens, ExchangeV3),
          deployer.link(ExchangeGenesis, ExchangeV3),
          deployer.link(ExchangeDeposits, ExchangeV3),
          deployer.link(ExchangeWithdrawals, ExchangeV3)
        ]);
      })
      .then(() => {
        console.log(">>>>>>>> contracts deployed by deploy_exchange:");
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
        return Promise.all([deployer.deploy(ExchangeV3, { gas: 6700000 })]);
      })
      .then(() => {
        console.log("WETHToken:", WETHToken.address);
        console.log("LRCToken:", LRCToken.address);
        console.log("ExchangeV3:", ExchangeV3.address);
        console.log("");
      });
  }
};
