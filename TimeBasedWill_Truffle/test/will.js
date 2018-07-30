const TimeBasedWill = artifacts.require("./TimeBasedWill.sol");
const { increaseTime } = require("./utils/increaseTime.js");
// truffleAssert for getting the events printed
// const truffleAssert = require('truffle-assertions');

// deployed behaves like a singleton. It will look if there is already an instance of the contract deployed to the blockchain via deployer.deploy. The information about which contract has which address on which network is stored in the build folder. 
// new will always create a new instance.
// It depends on your testcase, but I prefer not using deployed in unit tests in order to avoid side-effects and better isolate the unit tests.

// Using async/await on the same account has some threading issues where some tests randomly fail
// Check the link -> https://github.com/trufflesuite/truffle/issues/557
// Using different accounts for each of the test cases solves this issue for now

contract('TimeBasedWill', function(accounts) {

  var owner = accounts[0];
  //let timeWillObj;

//   beforeEach('setup contract for each test', async function () {
//     // new will create a new instance
//     timeWillObj = await TimeBasedWill.new(10, {from: owner});
//     //const timeWillAddress = timeWillObj.address;
//   });

  it("Check contract balance", async () => {
    let timeWillObj = await TimeBasedWill.new(10, {from: owner, value: 5000});
    assert.equal(web3.eth.getBalance(timeWillObj.address).toNumber(), 5000);
  });

  it("Adding/Removing Beneficiaries", async () => {
    let timeWillObj = await TimeBasedWill.new(10, {from: owner, value: 5000});
    assert.equal(web3.eth.getBalance(timeWillObj.address).toNumber(), 5000);
    await timeWillObj.addBeneficiary(accounts[1]);
    await timeWillObj.addBeneficiary(accounts[2]);
    await timeWillObj.addBeneficiary(accounts[3]);
    await timeWillObj.removeBeneficiary(accounts[2]);
    await increaseTime(11);
    var original_balance_1 = web3.eth.getBalance(accounts[1]).toNumber();
    var original_balance_3 = web3.eth.getBalance(accounts[3]).toNumber();
    await timeWillObj.claimOwnership();
    assert.equal(web3.eth.getBalance(accounts[1]).toNumber(), original_balance_1 + 2500);
    assert.equal(web3.eth.getBalance(accounts[3]).toNumber(), original_balance_3 + 2500);
  });

  it("Approve beneficiary addresses", async () => {
    let timeWillObj = await TimeBasedWill.new(10, {from: owner, value: 6000});
    assert.equal(web3.eth.getBalance(timeWillObj.address).toNumber(), 6000);
    await timeWillObj.approveAddresses([accounts[4], accounts[5], accounts[6]]);
    await increaseTime(11);
    var original_balance_4 = web3.eth.getBalance(accounts[4]).toNumber();
    var original_balance_6 = web3.eth.getBalance(accounts[6]).toNumber();
    await timeWillObj.claimOwnership();
    assert.equal(web3.eth.getBalance(accounts[4]).toNumber(), original_balance_4 + 2000);
    assert.equal(web3.eth.getBalance(accounts[6]).toNumber(), original_balance_6 + 2000);
  });


  it("Decrease expiry time", async () => {
    // Original expiry - 50 sec
    let timeWillObj = await TimeBasedWill.new(50, {from: owner, value: 4000});
    assert.equal(web3.eth.getBalance(timeWillObj.address).toNumber(), 4000);
    await timeWillObj.approveAddresses([accounts[7], accounts[8]]);
    // New expiry 10sec
    await timeWillObj.changeExpiry(10);
    await increaseTime(10);
    var original_balance_7 = web3.eth.getBalance(accounts[7]).toNumber();
    var original_balance_8 = web3.eth.getBalance(accounts[8]).toNumber();
    await timeWillObj.claimOwnership();
    assert.equal(web3.eth.getBalance(accounts[7]).toNumber(), original_balance_7 + 2000);
    assert.equal(web3.eth.getBalance(accounts[8]).toNumber(), original_balance_8 + 2000);
  });

});
