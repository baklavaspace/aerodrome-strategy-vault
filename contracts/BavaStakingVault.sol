// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IVelodromeGauge} from "./interfaces/aerodrome/IVelodromeGauge.sol";
import {ISolidlyRouter} from "./interfaces/aerodrome/ISolidlyRouter.sol";
import {ISolidlyPair} from "./interfaces/aerodrome/ISolidlyPair.sol";
import {IRewardDistributor} from "./interfaces/IRewardDistributor.sol";

import {Types} from './lib/Types.sol';
import {SingleSideBaseVault} from "./vaults/SingleSideBaseVault.sol";

// BavaStakingVault is the vault of Baklava Space's BAVA token.
// Note that it's ownable and the owner wields tremendous power.

contract BavaStakingVault is
    Initializable,
    UUPSUpgradeable,
    SingleSideBaseVault
{
    using SafeERC20 for IERC20;

    // ============ Constants ============
    
    address internal constant WETH = 0x4200000000000000000000000000000000000006;
    uint256 internal constant PRECISION = 1e30;

    // ============ Events ============

    event Claim(address indexed account, uint256 tokenAmount);
    event DepositsEnabled(bool newValue);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /********************************* INITIAL SETUP *********************************/
    /**
     * @dev Init the vault. Support LP from Fx-Swap masterChef.
     */
    function initVault(
        address _distributor
    ) external onlyRole(OWNER_ROLE) {
        distributor = _distributor;
        depositsEnabled = true;
    }

    /****************************************** FARMING CORE FUNCTION ******************************************/
    /**
     * @notice Deposit LP tokens to staking farm.
     */
    function deposit(uint256 _assets, address _receiver) public nonReentrant override returns (uint256) {
        require(depositsEnabled == true, "Deposit !enabled");

        _claim(msg.sender, _receiver);

        uint256 shares = super.deposit(_assets, _receiver);

        return shares;
    }

    // Withdraw LP tokens from BavaMasterFarmer. argument "_shares" is receipt amount.
    function redeem(uint256 _shares, address _receiver, address _owner) public nonReentrant override returns (uint256) {
        uint256 depositTokenAmount = previewRedeem(_shares);
        uint256 assets;

        _claim(msg.sender, msg.sender);

        if (depositTokenAmount > 0) {
            assets = super.redeem(_shares, _receiver, _owner);
        }

        return assets;
    }

    // Update reward variables of the given vault to be up-to-date.
    function claimReward(address receiver) external nonReentrant returns (uint256) {
        return _claim(msg.sender, receiver);
    }

    function updateRewards() external nonReentrant {
        _updateRewards(address(0));
    }

    /**************************************** Internal FUNCTIONS ****************************************/
    // Claim bonus reward from Baklava
    function _claim(address account, address receiver) private returns (uint256) {
        _updateRewards(account);
        Types.UserInfo storage user = userInfo[account];
        uint256 tokenAmount = user.claimableReward;
        user.claimableReward = 0;

        if (tokenAmount > 0) {
            IERC20(rewardToken()).safeTransfer(receiver, tokenAmount);
            emit Claim(account, tokenAmount);
        }

        return tokenAmount;
    }

    function _updateRewards(address account) private {
        uint256 blockReward = IRewardDistributor(distributor).distribute(address(this));

        uint256 supply = totalSupply();
        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        if (supply > 0 && blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken + (blockReward * (PRECISION) / (supply));
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // cumulativeRewardPerToken can only increase
        // so if cumulativeRewardPerToken is zero, it means there are no rewards yet
        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        if (account != address(0)) {
            Types.UserInfo storage user = userInfo[account];
            uint256 stakedAmount = balanceOf(account);
            uint256 accountReward = stakedAmount * (_cumulativeRewardPerToken - (user.previousCumulatedRewardPerToken)) / (PRECISION);
            uint256 _claimableReward = user.claimableReward + (accountReward);

            user.claimableReward = _claimableReward;
            user.previousCumulatedRewardPerToken = _cumulativeRewardPerToken;
        }
    }

    /**************************************** VIEW FUNCTIONS ****************************************/
    function rewardToken() public view returns (address) {
        return IRewardDistributor(distributor).rewardToken();
    }

    // View function to see pending Bavas on frontend.
    function claimable(address account) public view returns (uint256) {
        Types.UserInfo memory user = userInfo[account];
        uint256 stakedAmount = balanceOf(account);
        if (stakedAmount == 0) {
            return user.claimableReward;
        }
        uint256 supply = totalSupply();
        uint256 pendingRewards = IRewardDistributor(distributor).pendingRewards(address(this)) * (PRECISION);
        uint256 nextCumulativeRewardPerToken = cumulativeRewardPerToken + (pendingRewards / (supply));
        return user.claimableReward + (
            stakedAmount * (nextCumulativeRewardPerToken - (user.previousCumulatedRewardPerToken)) / (PRECISION));
    }

    // View function to see pending 3rd party reward. Inherit from AerodromeStrategyVault
    function checkReward() public pure returns (uint256) {
        return (0);
    }

    // View function to see pending 3rd party reward. Ignore bonus reward view to reduce code error due to 3rd party contract changes
    function getFeesInfo() public view returns (uint256, uint256, uint256) {
        return (feeOnReward, feeOnCompounder, feeOnWithdrawal);
    }

    /**************************************** ONLY OWNER FUNCTIONS ****************************************/

    // @notice Rescue any token function, just in case if any user not able to withdraw token from the smart contract.
    function rescueDeployedFunds(
        address token,
        uint256 amount,
        address _to
    ) external onlyRole(OWNER_ROLE) {
        require(_to != address(0), "0Addr");
        IERC20(token).safeTransfer(_to, amount);
    }

    // @notice Enable/disable deposits
    function updateDepositsEnabled(bool newValue) public onlyRole(OWNER_ROLE) {
        require(depositsEnabled != newValue);
        depositsEnabled = newValue;
        emit DepositsEnabled(newValue);
    }

    /**************************************** ONLY AUTHORIZED FUNCTIONS ****************************************/

    function updateFeeBips(Types.StrategySettings memory _strategySettings)
        public
        onlyRole(GOVERNOR_ROLE)
    {
        feeOnReward = _strategySettings.feeOnReward;
        feeOnCompounder = _strategySettings.feeOnCompounder;
        feeOnWithdrawal = _strategySettings.feeOnWithdrawal;
    }

    function updateFeeTreasury(address _feeTreasury)
        public
        onlyRole(GOVERNOR_ROLE)
    {
        feeTreasury = _feeTreasury;
    }
    
    function updateDistributor(address _distributor)
        public
        onlyRole(GOVERNOR_ROLE)
    {
        distributor = _distributor;
    }

    /*********************** Openzeppelin inherited functions *********************************/
    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256 value)
        internal
        virtual
        override
    {
        _updateRewards(from);
        _updateRewards(to);
        super._update(from, to, value);
    }

    function _authorizeUpgrade(address) internal override onlyRole(OWNER_ROLE) {}

    /**************************************************************
     * @dev Initialize smart contract functions - only called once
     * @param symbol: BRT2LPSYMBOL
     *************************************************************/
    function initialize(
        address _asset,
        address _owner,
        address _governor,
        string memory name_,
        string memory symbol_
    ) public initializer {
        __SingleSideBaseVaultInit(
            _asset,
            name_,
            symbol_,
            _owner,
            _governor
        );
        __UUPSUpgradeable_init();
    }
}