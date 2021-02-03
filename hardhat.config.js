/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require("@nomiclabs/hardhat-waffle");
var chai = require('chai');
chai.use(require('chai-string'));

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: {
    version: "0.5.17"
  },
  paths: {
    root: './resources/public/contracts',
    artifacts: 'build',
    sources: 'src'
  },
  loggingEnabled: true,
  networks: {
    hardhat: {
      chainId: 1337
    },
  }
};
