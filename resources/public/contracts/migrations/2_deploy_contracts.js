const AuctionOffering = artifacts.require("AuctionOffering");

module.exports = function(deployer) {
  // TODO: deploy all other contracts
  deployer.deploy(AuctionOffering);
};
