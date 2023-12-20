// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Treasury
 * @author Baklava
 *
 * @notice Holds WFX token. Allows the owner to transfer the token or set allowances.
 */
contract FeeTreasury is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    uint256 private constant REVISION = 1;

    event Received(address, uint);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getRevision() internal pure returns (uint256) {
        return REVISION;
    }

    function recoverToken(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        require(recipient != address(0), "Send to zero address");
        token.safeTransfer(recipient, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function initialize(address _owner) external initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
    }
}
