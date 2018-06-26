pragma solidity ^0.4.23;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * Reference: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */

contract Ownable {
    
    address internal m_owner;
    
    event OwnershipRenounced(address indexed owner);
    
    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
    );
    
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public
    {
        m_owner = msg.sender;
    }
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner()
    {
        require(msg.sender == m_owner, "Only Owner allowed to modify contract");
        _;
    }
    
    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address new_owner) public onlyOwner
    {   
        _transferOwnership(new_owner);
    }

    function _transferOwnership(address new_owner) internal {
        require(new_owner != address(0));
        emit OwnershipTransferred(m_owner, new_owner);
        m_owner = new_owner;
    }
    
    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner payable
    {
        emit OwnershipRenounced(m_owner);
        m_owner.transfer(address(this).balance);
        m_owner = address(0);
    }
}