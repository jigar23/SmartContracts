pragma solidity ^0.4.23;
import "browser/Ownable.sol";
import "browser/Arrays.sol";

/**
 * @title TimeBasedWill
 * @dev TimeBasedWill provides ether transfer functionalities to owner's
 *  beneficiaries based on a timer.
 *  - Owner can set the timer(in seconds) to approximately the time they think they'll die
 *      They can change the expiry duration any time.
 *  - Beneficiaries can be added/removed before the expiry time.
 *  - Funds can be added/removed from the contract before the expiry time ONLY by the owner. 
 *  - Once the timer is up, anyone can call the function claimOwnership() and the funds
 *      will be transferred to the beneficiaries.
 *  - There are 2 additional functionalities which should be used VERY CAREFULLY
 *      TranferOwnership - This will transfer the onwership of the contract to the new owner.
 *          New Owner will now be able to control all funds in the contract.
 *      RenounceOwnership - This will renounce the contracts ownership and transfer the funds
 *          present in the contract back to the owner.
 */
contract TimeBasedWill is Ownable {
    
    using AddressArrayExtended for address[];
    address[] private m_beneficiaries;
    uint private m_expiryTime;
    
    /**
    * @dev Throw an exception if called before the expiry time
    */
    modifier beforeExpiry {
        require(now < m_expiryTime, "This action should have been done only BEFORE expiry");
        _;
    }
    
    /**
    * @dev Throw an exception if called after the expiry time
    */
    modifier afterExpiry {
        require(now >= m_expiryTime, "This action can be done only AFTER expiry");
        _;
    }
    
    /**
    * @dev constructor which sets the original owner
    * @param expiryDuration timer will be set from now to (now + expiryDuration)
    * @notice Throws an exception if no funds are added to the contract
    */
    constructor(uint expiryDuration) public payable
    {   
        require(address(this).balance > 0, "Please add some initial funds to the Will");
        require(expiryDuration >= 60, "Expiry time should be atleast 60 sec");
        m_expiryTime = now + expiryDuration;
    }
    
    /**
    * @dev Changes the expiryDuration overriding the previous one
    * @notice Throws an exception if done after Expiry
    */
    function changeExpiry(uint expiryDuration) onlyOwner beforeExpiry public
    {
        m_expiryTime = now + expiryDuration;
    }
    
    /**
    * @dev Adds the list of addresses as beneficiaries
    * @notice Throws an exception if onwer is added as benefeciary
    */
    function approveAddresses(address[] beneficiaries) public
    {   
        for (uint i = 0; i < beneficiaries.length; i++) {
            addBeneficiary(beneficiaries[i]);
        }
    }
    
    // As of now, we can enter the same benefeciary multiple times
    function addBeneficiary(address newBeneficiary) public onlyOwner beforeExpiry
    {   
        require(newBeneficiary != m_owner, "Cannot add owner as beneficiary");
        require(newBeneficiary != address(0), "Enter a valid address");
        m_beneficiaries.push(newBeneficiary);
    }
    
    /**
    * @dev Removes the benefeciary from the list of approved ones
    * @notice Throws an exception if benefeciary was not added originally
    */
    function removeBeneficiary(address beneficiary) public onlyOwner beforeExpiry
    {
       require(m_beneficiaries.removeValue(beneficiary), "Address Not Found");
    }
    
    /**
    * @dev Anyone can call this function after Expiry and funds will be transferred
    * from the contract to the benefeciaries
    */
    function claimOwnership() public payable afterExpiry 
    {   
        uint num_beneficiaries = m_beneficiaries.length;
        require(num_beneficiaries > 0, "Add some beneficiaries to distribute");
        require(address(this).balance >= num_beneficiaries * 1 wei, 
                "Balance should be atleast num_beneficiaries * 1 wei");
        
        uint shareOfAddress = address(this).balance/num_beneficiaries;
        
        for (uint i = 0; i < num_beneficiaries; i++) {
            address value = m_beneficiaries[i];
            value.transfer(shareOfAddress);
        }
    }
    
    /**
    * @dev The owner can add more funds to the contract
    */
    function addFunds() public payable onlyOwner beforeExpiry {
    }
    
    /**
    * @dev The owner can remove funds from the contract
    */
    function removeFunds(uint amount) public payable onlyOwner beforeExpiry {
        require(amount > 0, "Add some value to remove funds");
        require(address(this).balance >= amount, "Balance insufficient to remove funds");
        m_owner.transfer(amount);
    }
}