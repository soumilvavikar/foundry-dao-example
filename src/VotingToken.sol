// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

/**
 * @title VotingToken
 * @author Soumil Vavikar
 * @notice A simple ERC20 token with voting capabilities
 * @dev This contract uses OpenZeppelin's ERC20, ERC20Permit, and ERC20Votes contracts to create a token with voting capabilities
 * @dev The contract also uses the Nonces contract to keep track of permit nonces
 * @dev - downloaded from https://docs.openzeppelin.com/contracts/5.x/governance 
 */
contract VotingToken is ERC20, ERC20Permit, ERC20Votes {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {}

    // The functions below are overrides required by Solidity.

    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);
    }

    function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}