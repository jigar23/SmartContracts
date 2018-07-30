# SmartContracts
This repository contains smart contracts built on Ethereum platform

1. TimeBasedWill

TimeBasedWill provides ether transfer functionalities to owner's beneficiaries based on a timer.
- Owner can set the timer(in seconds) to approximately the time they think they'll die
  They can change the expiry duration any time before the expiry timer is up.
- Beneficiaries can be added/removed before the expiry time ONLY by the owner.
 - Funds can be added/removed from the contract before the expiry time ONLY by the owner. 
 - Once the timer is up, anyone can call the function claimOwnership() and the funds
   will be transferred to the beneficiaries.
 - There are 2 additional functionalities which should be used VERY CAREFULLY
    - TranferOwnership - This will transfer the onwership of the contract to the new owner.
        New Owner will now be able to control all funds in the contract.
    - RenounceOwnership - This will renounce the contracts ownership and transfer the funds
        present in the contract back to the owner.
        
 2. TimeBasedWill_Truffle
 
 - Extending the contract to run in truffle with testrpc
 - Added test cases in Javascript to test basic functionalities
 
 To Do's:
 - Use Safe Math Library
 - Use https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/payment/SplitPayment.sol to split the share
