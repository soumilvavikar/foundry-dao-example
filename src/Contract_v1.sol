// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ContractV1
 * @author Soumil Vavikar
 * @notice A simple contract to store a value
 */
contract ContractV1 is Ownable {
    // Storage for a value
    uint256 public s_value;
    // Emitted when the stored value changes

    event ValueChanged(uint256 newValue);

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Set the stored value
     * @param _value The new value to store
     * @dev Only the owner can call this function
     */
    function setValue(uint256 _value) public onlyOwner {
        s_value = _value;
        emit ValueChanged(_value);
    }

    /**
     * @notice Get the stored value
     */
    function getValue() public view returns (uint256) {
        return s_value;
    }
}
