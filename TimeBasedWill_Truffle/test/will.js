const TimeBasedWill = artifacts.require("./TimeBasedWill.sol");
const { increaseTime } = require("./utils/increaseTime.js");

// deployed behaves like a singleton. It will look if there is already an instance of the contract deployed to the blockchain via deployer.deploy. The information about which contract has which address on which network is stored in the build folder. 
// new will always create a new instance.
// It depends on your testcase, but I prefer not using deployed in unit tests in order to avoid side-effects and better isolate the unit tests.

// Using async/await on the same account has some threading issues where some tests randomly fail
// Check the link -> https://github.com/trufflesuite/truffle/issues/557
// Using different accounts for each of the test cases solves this issue for now

// Works only the first time you start testrpc
// Weirdly it keeps adding the multiple balances in subsequent runs

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

  it("Adding Beneficiaries", async () => {
    let timeWillObj = await TimeBasedWill.new(10, {from: owner, value: 1000});
    assert.equal(web3.eth.getBalance(timeWillObj.address).toNumber(), 1000);
    await timeWillObj.addBeneficiariesWithPercentShares([accounts[1], accounts[2], accounts[3]],[30,30,40]);
    await increaseTime(11);
    var original_balance_2 = await web3.eth.getBalance(accounts[2]).toNumber();
    console.log(`Initial Balance: ${original_balance_2}`);
    // To estimate gas usage
    //const gasCost = await timeWillObj.claimOwnership.estimateGas({from: accounts[1]});
  
    const hash = await timeWillObj.claimOwnership({from: accounts[2]});
    const gasUsed = hash.receipt.gasUsed;
    console.log(`GasUsed: ${hash.receipt.gasUsed}`);

    // Obtain gasPrice from the transaction
    const tx = await web3.eth.getTransaction(hash.tx);
    console.log(`Contract Address: ${timeWillObj.address}`);
    console.log(`Contract Balance: ${web3.eth.getBalance(timeWillObj.address).toNumber()}`);
    console.log(`Account Address: ${accounts[1]}`);
    console.log(`To: ${tx.to}`);
    console.log(`From: ${tx.from}`);
    console.log(`Value: ${tx.value}`);
    
    const gasPrice = tx.gasPrice;
    console.log(`GasPrice: ${tx.gasPrice}`);

    // Final balance
    const final = await web3.eth.getBalance(accounts[2]);
    console.log(`Final: ${final.toString()}`);

    assert.equal(final.add(gasPrice.mul(gasUsed)).sub(300).toString(), original_balance_2.toString(), "Must be equal");
  });

  it("Adding/Removing Beneficiaries", async() => {
    let timeWillObj = await TimeBasedWill.new(10, {from: owner, value: 5000});
    assert.equal(web3.eth.getBalance(timeWillObj.address).toNumber(), 5000);
    await timeWillObj.addBeneficiariesWithPercentShares([accounts[1], accounts[2], accounts[3]],[30,30,40]);

    // Change the accounts
    await timeWillObj.addBeneficiariesWithPercentShares([accounts[4], accounts[5], accounts[6]],[30,30,40]);
    await increaseTime(11);
    var original_balance_5 = await web3.eth.getBalance(accounts[5]).toNumber();

    const hash = await timeWillObj.claimOwnership({from: accounts[5]});
    const gasUsed = hash.receipt.gasUsed;
    const tx = await web3.eth.getTransaction(hash.tx);
    const gasPrice = tx.gasPrice;
    const final_5 = await web3.eth.getBalance(accounts[5]);
    console.log(`Final: ${final_5.toString()}`);

    assert.equal(final_5.add(gasPrice.mul(gasUsed)).sub(1500).toString(), original_balance_5.toString(), "Must be equal");
  });

  it("Decrease expiry time", async () => {
    // Original expiry - 50 sec
    let timeWillObj = await TimeBasedWill.new(50, {from: owner, value: 4000});
    assert.equal(web3.eth.getBalance(timeWillObj.address).toNumber(), 4000);
    await timeWillObj.addBeneficiariesWithPercentShares([accounts[1], accounts[2], accounts[3]],[20,30,50]);
    // New expiry 10sec
    await timeWillObj.changeExpiry(10);
    await increaseTime(10);
    var original_balance_3 = await web3.eth.getBalance(accounts[3]).toNumber();

    const hash = await timeWillObj.claimOwnership({from: accounts[3]});
    const gasUsed = hash.receipt.gasUsed;
    const tx = await web3.eth.getTransaction(hash.tx);
    const gasPrice = tx.gasPrice;
    const final_3 = await web3.eth.getBalance(accounts[3]);
    console.log(`Final: ${final_3.toString()}`);

    assert.equal(final_3.add(gasPrice.mul(gasUsed)).sub(2000).toString(), original_balance_3.toString(), "Must be equal");
  });

  //Changing the ownership
  it("Change ownership", async () => {
    let timeWillObj = await TimeBasedWill.new(10, {from: owner, value: 4000});
    await timeWillObj.transferOwnership(accounts[7]);
    assert.equal(web3.eth.getBalance(timeWillObj.address).toNumber(), 4000);
    await timeWillObj.addBeneficiariesWithPercentShares([accounts[4], accounts[5], accounts[6]],[20,30,50], {from: accounts[7]});

    var original_balance_7 = await web3.eth.getBalance(accounts[7]).toNumber();
    const hash = await timeWillObj.renounceOwnership({from: accounts[7]});
    const gasUsed = hash.receipt.gasUsed;
    const tx = await web3.eth.getTransaction(hash.tx);
    const gasPrice = tx.gasPrice;
    const final_7 = await web3.eth.getBalance(accounts[7]);

    assert.equal(final_7.add(gasPrice.mul(gasUsed)).sub(4000).toString(), original_balance_7.toString(), "Must be equal");
  });

});
