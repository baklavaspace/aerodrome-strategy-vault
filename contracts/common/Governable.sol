// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract Governable is AccessControlUpgradeable {
    bytes32 public constant OWNER_ROLE = bytes32("OWNER_ROLE");
    bytes32 public constant GOVERNOR_ROLE = bytes32("GOVERNOR_ROLE");
    bytes32 public constant OPERATOR_ROLE = bytes32("OPERATOR_ROLE");       // only contract address

    function __Governable_init(address _owner, address _governor) internal {
        __AccessControl_init();
        
        // Assign roles to the sender.
        _grantRole(OWNER_ROLE, _owner);
        _grantRole(GOVERNOR_ROLE, _governor);

        // Set OWNER_ROLE as the admin of all roles.
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(GOVERNOR_ROLE, OWNER_ROLE);
        _setRoleAdmin(OPERATOR_ROLE, OWNER_ROLE);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}