// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBRTVault} from "./interfaces/IBRTVault.sol";
import {IRewardDistributor} from "./interfaces/IRewardDistributor.sol";

contract MultiCall is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;

    address rewardDistributor;

    struct VaultInfo {
        uint256 totalSupply;
        uint256 totalAssets;
        uint256 reinvestReward;
    }

    struct VaultUserDepositInfo {
        uint256 depositAmount;
        uint256 reward;
        uint256 allowance;
        uint256 balance;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**************************************** Public/External View Functions ****************************************
    /**
    * @dev Get all validator delegation for stFX.
    */
    function getAllVaultInfo() external view returns (VaultInfo[] memory vaultInfo) {
        uint256 vaultLength = IRewardDistributor(rewardDistributor).getRewardTrackerLength();

        vaultInfo = new VaultInfo[](vaultLength);

        for (uint256 i = 0; i < vaultLength; i++) {
            (,address vaultAddress,) = IRewardDistributor(rewardDistributor).trackerInfo(i);
 
            uint256 _totalSupply = IBRTVault(vaultAddress).totalSupply();
            uint256 _totalAssets = IBRTVault(vaultAddress).totalAssets();
            uint256 _reinvestReward = IBRTVault(vaultAddress).checkReward();

            vaultInfo[i] = VaultInfo({
                totalSupply: _totalSupply,
                totalAssets: _totalAssets,
                reinvestReward: _reinvestReward
            });
        }
    }

    /**
    * @dev Get All Validator User Delegation
    */
    function getAllVaultUserDepositInfo(address user) external view returns (VaultUserDepositInfo[] memory vaultUserDeposit) {
        uint256 vaultLength = IRewardDistributor(rewardDistributor).getRewardTrackerLength();

        vaultUserDeposit = new VaultUserDepositInfo[](vaultLength);

        for (uint256 i = 0; i < vaultLength; i++) {
            (,address vaultAddress,) = IRewardDistributor(rewardDistributor).trackerInfo(i);
            address depositToken = IBRTVault(vaultAddress).asset();
            
            uint256 _depositAmount = IBRTVault(vaultAddress).balanceOf(user);
            uint256 _reward = IBRTVault(vaultAddress).claimable(user);
            uint256 _allowance = IERC20(depositToken).allowance(user, vaultAddress);
            uint256 _balance = IERC20(depositToken).balanceOf(user);

            vaultUserDeposit[i] = VaultUserDepositInfo({
                depositAmount: _depositAmount,
                reward: _reward,
                allowance: _allowance,
                balance: _balance
            });
        }
    }

    /**************************************** Only Owner Functions ****************************************/

    function updateRewardDistributor(
        address _rewardDistributor
    ) external onlyOwner() {
        require(_rewardDistributor != address(0), "Cannot 0 add");
        require(_rewardDistributor != rewardDistributor, "Cannot same add");
        rewardDistributor = _rewardDistributor;
    }

    function recoverToken(
        address token,
        uint256 amount,
        address _recipient
    ) external onlyOwner() {
        require(_recipient != address(0), "Send to zero address");
        IERC20(token).safeTransfer(_recipient, amount);
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyOwner() {} 

    /**************************************************************
     * @dev Initialize the states
     *************************************************************/

    function initialize(address _rewardDistributor, address _owner) public initializer {
        rewardDistributor = _rewardDistributor;

        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
    }
}