var ArrayLib = artifacts.require("./AddressArrayExtended.sol");
var Ownable = artifacts.require("./Ownable.sol");
var Will = artifacts.require("./TimeBasedWill.sol");

module.exports = function(deployer) {
  // deploy the library first
  deployer.deploy(ArrayLib);
  deployer.link(ArrayLib, Will);
  //deployer.autolink();
  deployer.deploy(Will, 2);
  deployer.deploy(Ownable);
  deployer.link(Ownable, Will);
};
