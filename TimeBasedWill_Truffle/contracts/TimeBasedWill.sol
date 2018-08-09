pragma solidity ^0.4.23;
import "./Ownable.sol";
import "./AddressArrayExtended.sol";
import "./SafeMath.sol";

/**
 * @title TimeBasedWill
 * @dev TimeBasedWill provides ether transfer functionalities to owner's
 *  beneficiaries based on a timer.
 *  - Owner can set the timer(in seconds) to approximately the time they think they want to transfer
 *      They can change the expiry duration any time before the last expiry time expires
 *  - Owner can Add beneficiaries with percent shares for individual beneficiaries
 *  - Funds can be added/removed from the contract before the expiry time ONLY by the owner.
 *  - Once the timer is up, beneficiaries can claim their ownership ONCE.
 *  - There are 2 additional functionalities which should be used VERY CAREFULLY
 *      TranferOwnership - This will transfer the onwership of the contract to the new owner.
 *          New Owner will now be able to control all funds in the contract.
 *      RenounceOwnership - This will renounce the contracts ownership and transfer the funds
 *          present in the contract back to the owner.
 */
contract TimeBasedWill is Ownable {

    using AddressArrayExtended for address[];
    using SafeMath for uint;
    using SafeMath8 for uint8;

    event transferred_value(address beneficiary, uint balance);

    struct Share {
        uint8 m_percent_share;
        bool m_claimed_ownership;
    }

    address[] public m_beneficiaries;
    mapping(address => Share) public m_beneficiary_shares;
    uint public m_expiryTime;
    uint private m_funds_allocated;

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
        //require(address(this).balance > 0, "Please add some initial funds to the Will");
        require(expiryDuration >= 1, "Expiry time should be atleast 1 sec");
        m_expiryTime = expiryDuration.add(now);
        m_funds_allocated = address(this).balance;
    }

    /**
    * @dev Changes the expiryDuration overriding the previous one
    * @notice Throws an exception if done after Expiry
    */
    function changeExpiry(uint expiryDuration) onlyOwner beforeExpiry public
    {
        m_expiryTime = expiryDuration.add(now);
    }

    /**
    * @dev Adds the list of addresses as beneficiaries along with their individual shares
    * @notice Throws an exception if 
    *   - owner is added as beneficiary
    *   - Num of beneficiary > 255
    *   - Total shares dont add to 100
    */
    function addBeneficiariesWithPercentShares(address[] beneficiaries, uint8[] shares) public onlyOwner beforeExpiry
    {   
        require(beneficiaries.length == shares.length, "beneficiary and shares array length to be same");
        uint8 total_shares = 0;
        for (uint i = 0; i < beneficiaries.length; i++) {
            require(beneficiaries[i] != m_owner, "Cannot add owner as beneficiary");
            require(beneficiaries[i] != address(0), "Enter a valid address");
            require(shares[i] > 0 && shares[i] <= 100, "Share has to > 0 & <= 100");
            total_shares = total_shares.add(shares[i]);
        }
        require(total_shares == 100, "Total shares should add to 100%");
        _addBeneficiariesWithPercentShares(beneficiaries, shares);
    }

    function _addBeneficiariesWithPercentShares(address[] beneficiaries, uint8[] shares) internal
    {   
        // Will override the previous added beneficiaries
        // Instead of clearing the previous array, if we override then its takes less gas
        uint min_length = 0;
        if (m_beneficiaries.length <= beneficiaries.length) {
            min_length = m_beneficiaries.length;
        }
        else {
            min_length = beneficiaries.length;
        }

        // For min length, override the current elements
        uint8 index = 0;
        for (index; index < min_length; index++) {
            delete m_beneficiary_shares[m_beneficiaries[index]];
            m_beneficiaries[index] = beneficiaries[index];
            m_beneficiary_shares[m_beneficiaries[index]] = Share(shares[index], false);
        }
        // If more elements added than previously present, push the new elements to the array
        // and add them to the map
        if (min_length == m_beneficiaries.length) {
            for (index; index < beneficiaries.length; index++) {
                m_beneficiaries.push(beneficiaries[index]);
                m_beneficiary_shares[m_beneficiaries[index]] = Share(shares[index], false);                
            }
        }
        // If lesser elements added than previously present, remove the extra elements from the array
        // and delete them from the map
        else {
            for (uint i = m_beneficiaries.length-1; i >= index; i--) {
                address beneficiary = m_beneficiaries[i];
                delete m_beneficiaries[i];
                delete m_beneficiary_shares[beneficiary];
            }
            m_beneficiaries.length = min_length;
        }
    }

    /**
    * @dev Beneficiaries can call this after expiry to claim their ownership
    * @notice Once the transfer is done, subsequent calls will throw an error
    */
    function claimOwnership() public payable afterExpiry
    {   
        address payee = msg.sender;
        Share storage payee_share = m_beneficiary_shares[payee];

        require(payee_share.m_percent_share > 0, "Address not present in the list of beneficiaries or no shares allocated");
        require(payee_share.m_claimed_ownership == false, "Address has already claimed ownership");
        
        payee_share.m_claimed_ownership = true;
        uint value = m_funds_allocated.mul(payee_share.m_percent_share).div(100);
        require(value != 0);
        payee.transfer(value);
        emit transferred_value(payee, value);
    }

    /**
    * @dev The owner can add more funds to the contract
    */
    function addFunds() public payable onlyOwner beforeExpiry {
        m_funds_allocated = address(this).balance;
    }

    /**
    * @dev The owner can remove funds from the contract
    */
    function removeFunds(uint amount) public payable onlyOwner beforeExpiry {
        require(amount > 0, "Add some value to remove funds");
        require(address(this).balance >= amount, "Balance insufficient to remove funds");
        m_owner.transfer(amount);
        m_funds_allocated = address(this).balance;
    }
}
