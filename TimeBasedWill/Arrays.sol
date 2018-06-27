pragma solidity ^0.4.23;

/**
* @dev Extended library for address array
*/
library AddressArrayExtended {
    
    /**
    * @dev Removes the address *value* from the list of _self[]
    * @notice Returns false if value is not found
    */
    function removeValue(address[] storage _self, address value) public returns (bool)
    {
        require(_self.length > 0, "No values added");
        bool foundValue = false;
        
        // If found, push the last element to the found index and delete the 
        // last element
        for (uint i = 0; i < _self.length; i++) {
            if (_self[i] == value) {
                _self[i] = _self[_self.length-1];
                foundValue = true;
                break;
            }
        }
        if (foundValue) {
            delete _self[_self.length-1];
            _self.length--;
        }
        return foundValue;
    }
}