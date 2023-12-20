// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
import {BaseVault} from "./vaults/BaseVault.sol";

// AerodromeStrategyVault is the compoundVault of Aerodrome Gauge. It will autocompound user LP.
// Note that it's ownable and the owner wields tremendous power.

contract AerodromeStrategyVault is
    Initializable,
    UUPSUpgradeable,
    BaseVault
{
    using SafeERC20 for IERC20;

    // ============ Constants ============
    
    address internal constant WETH = 0x4200000000000000000000000000000000000006;
    uint256 internal constant PRECISION = 1e30;

    // ============ Events ============

    event Claim(address indexed account, uint256 tokenAmount);
    event EmergencyWithdraw(address indexed owner, uint256 assets, uint256 shares);
    event EmergencyWithdrawVault(address indexed owner, bool disableDeposits);
    event DepositsEnabled(bool newValue);
    event RestakingEnabled(bool newValue);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /********************************* INITIAL SETUP *********************************/
    /**
     * @dev Init the vault. Support LP from Fx-Swap masterChef.
     */
    function initVault(
        address _stakingContract,
        address _poolRewardToken,
        IERC20[] memory _bonusRewardTokens,
        address _router,
        address _feeTreasury,
        address _distributor,
        ISolidlyRouter.Route[] calldata _outputToNativeRoute,
        ISolidlyRouter.Route[] calldata _outputToLp0Route,
        ISolidlyRouter.Route[] calldata _outputToLp1Route
    ) external onlyRole(OWNER_ROLE) {
        require(_stakingContract != address(0), "0 Add");

        stakingContract = IVelodromeGauge(_stakingContract);
        poolRewardToken = IERC20(_poolRewardToken);
        bonusRewardTokens = _bonusRewardTokens;
        router = ISolidlyRouter(_router);
        feeTreasury = _feeTreasury;
        distributor = _distributor;

        stable = ISolidlyPair(asset()).stable();
        for (uint i; i < _outputToNativeRoute.length; ++i) {
            outputToNativeRoute.push(_outputToNativeRoute[i]);
        }

        for (uint i; i < _outputToLp0Route.length; ++i) {
            outputToLp0Route.push(_outputToLp0Route[i]);
        }

        for (uint i; i < _outputToLp1Route.length; ++i) {
            outputToLp1Route.push(_outputToLp1Route[i]);
        }

        depositsEnabled = true;
        restakingEnabled = true;
    }

    /**
     * @notice Approve tokens for use in Strategy, Restricted to avoid griefing attacks
     */
    function approveAllowances(uint256 _amount) external onlyRole(GOVERNOR_ROLE) {
        address depositToken = asset();
        if (address(stakingContract) != address(0)) {
            IERC20(depositToken).approve(
                address(stakingContract),
                _amount
            );
        }

        if (address(router) != address(0)) {
            IERC20(WETH).approve(address(router), _amount);
            IERC20(ISolidlyPair(depositToken).token0()).approve(address(router), _amount);
            IERC20(ISolidlyPair(depositToken).token1()).approve(address(router), _amount);
            IERC20(depositToken).approve(address(router), _amount);
            poolRewardToken.approve(address(router), _amount);

            uint256 rewardLength = bonusRewardTokens.length;
            uint256 i = 0;
            for (i; i < rewardLength; i++) {
                bonusRewardTokens[i].approve(address(router), _amount);
            }
        }
    }

    /****************************************** FARMING CORE FUNCTION ******************************************/
    /**
     * @notice Deposit LP tokens to staking farm.
     */
    function deposit(uint256 _assets, address _receiver) public nonReentrant override returns (uint256) {
        require(depositsEnabled == true, "Deposit !enabled");
        
        uint256 estimatedTotalReward = checkReward();
        if (estimatedTotalReward > minTokensToReinvest) {
            _compound();
        }

        _claim(msg.sender, _receiver);

        uint256 shares = super.deposit(_assets, _receiver);

        if (restakingEnabled == true) {
            uint256 stakeAmount = IERC20(asset()).balanceOf(address(this));
            _depositTokens(stakeAmount);
        }

        return shares;
    }

    // Withdraw LP tokens from BavaMasterFarmer. argument "_shares" is receipt amount.
    function redeem(uint256 _shares, address _receiver, address _owner) public nonReentrant override returns (uint256) {
        uint256 depositTokenAmount = previewRedeem(_shares);
        uint256 assets;

        uint256 estimatedTotalReward = checkReward();
        if (estimatedTotalReward > minTokensToReinvest) {
            _compound();
        }

        _claim(msg.sender, msg.sender);

        if (depositTokenAmount > 0) {
            _withdrawTokens(depositTokenAmount);
            assets = super.redeem(_shares, _receiver, _owner);
        }

        if (restakingEnabled == true) {
            uint256 stakeAmount = IERC20(asset()).balanceOf(address(this));
            _depositTokens(stakeAmount);
        }

        return assets;
    }

    // EMERGENCY ONLY. Withdraw without caring about rewards.
    // This has the 25% fee withdrawals fees and ucer receipt record set to 0 to prevent abuse of thisfunction.
    function emergencyRedeem() external nonReentrant {
        Types.UserInfo storage user = userInfo[msg.sender];
        uint256 userBRTAmount = balanceOf(msg.sender);

        require(userBRTAmount > 0, "#>0");

        _updateRewards(msg.sender);
        user.claimableReward = 0;

        // Reordered from Sushi function to prevent risk of reentrancy
        uint256 assets = _convertToAssets(userBRTAmount, Math.Rounding.Floor);
        assets -= (assets * 2500) / BIPS_DIVISOR;

        _withdrawTokens(assets);

        _burn(msg.sender, userBRTAmount);
        IERC20(asset()).safeTransfer(address(msg.sender), assets);

        emit EmergencyWithdraw(msg.sender, assets, userBRTAmount);
    }

    function compound() external nonReentrant {
        uint256 estimatedTotalReward = checkReward();
        require(estimatedTotalReward >= minTokensToReinvest, "#<MinInvest");

        uint256 liquidity = _compound();

        if (restakingEnabled == true) {
            _depositTokens(liquidity);
        }
    }

    // Update reward variables of the given vault to be up-to-date.
    function claimReward(address receiver) external nonReentrant returns (uint256) {
        return _claim(msg.sender, receiver);
    }

    function updateRewards() external nonReentrant {
        _updateRewards(address(0));
    }

    /**************************************** Internal FUNCTIONS ****************************************/
    // Deposit LP token to 3rd party restaking farm
    function _depositTokens(uint256 amount) internal {
        if(amount > 0) {
            stakingContract.deposit(
                amount,
                address(this)
            );
        }
    }

    // Withdraw LP token to 3rd party restaking farm
    function _withdrawTokens(uint256 amount) internal {
        if(amount > 0) {
            uint256 depositAmount = balanceOfPool();

            if (depositAmount > 0) {
                uint256 pendingRewardAmount = stakingContract.earned(address(this));

                if (pendingRewardAmount == 0 || depositAmount < amount) {
                    stakingContract.withdraw(
                        depositAmount
                    );
                } else {
                    stakingContract.withdraw(
                        amount
                    );
                }
            }
        }
    }

    // Claim LP restaking reward from 3rd party restaking contract
    function _getReinvestReward() private {
        uint256 pendingRewardAmount = stakingContract.earned(
            address(this)
        );
        if (pendingRewardAmount > 0) {
            stakingContract.getReward(
                address(this)
            );
        }
    }

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

    // View function to see pending 3rd party reward. Ignore bonus reward view to reduce code error due to 3rd party contract changes
    function checkReward() public view returns (uint256) {
        uint256 pendingRewardAmount = stakingContract.earned(
            address(this)
        );
        uint256 rewardBalance = poolRewardToken.balanceOf(address(this));

        return (pendingRewardAmount + rewardBalance);
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

    // @notice Emergency withdraw all LP tokens from staking farm contract
    function emergencyWithdrawVault(bool disableDeposits)
        external
        onlyRole(OWNER_ROLE)
    {
        uint256 depositAmount = balanceOfPool();
        stakingContract.withdraw(depositAmount);

        if (depositsEnabled == true && disableDeposits == true) {
            updateDepositsEnabled(false);
            updateRestakingEnabled(false);
        }
        emit EmergencyWithdrawVault(msg.sender, disableDeposits);
    }

    // @notice Enable/disable deposits
    function updateDepositsEnabled(bool newValue) public onlyRole(OWNER_ROLE) {
        require(depositsEnabled != newValue);
        depositsEnabled = newValue;
        emit DepositsEnabled(newValue);
    }

    function updateRestakingEnabled(bool newValue) public onlyRole(OWNER_ROLE) {
        require(restakingEnabled != newValue);
        restakingEnabled = newValue;
        emit RestakingEnabled(newValue);
    }

    /**************************************** ONLY AUTHORIZED FUNCTIONS ****************************************/

    function updateStackingGauge(address _stakingContract)
        public
        onlyRole(GOVERNOR_ROLE)
    {
        stakingContract = IVelodromeGauge(_stakingContract);
    }

    function updateFeeBips(Types.StrategySettings memory _strategySettings)
        public
        onlyRole(GOVERNOR_ROLE)
    {
        minTokensToReinvest = _strategySettings.minTokensToReinvest;
        feeOnReward = _strategySettings.feeOnReward;
        feeOnCompounder = _strategySettings.feeOnCompounder;
        feeOnWithdrawal = _strategySettings.feeOnWithdrawal;
    }

    function updateBonusReward(IERC20[] memory _bonusRewardTokens)
        public
        onlyRole(GOVERNOR_ROLE)
    {
        bonusRewardTokens = _bonusRewardTokens;
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

    function updateRoute(
        ISolidlyRouter.Route[] calldata _outputToNativeRoute,
        ISolidlyRouter.Route[] calldata _outputToLp0Route,
        ISolidlyRouter.Route[] calldata _outputToLp1Route
    )
        public
        onlyRole(GOVERNOR_ROLE)
    {
        delete outputToNativeRoute;
        delete outputToLp0Route;
        delete outputToLp1Route;

        for (uint i; i < _outputToNativeRoute.length; ++i) {
            outputToNativeRoute.push(_outputToNativeRoute[i]);
        }

        for (uint i; i < _outputToLp0Route.length; ++i) {
            outputToLp0Route.push(_outputToLp0Route[i]);
        }

        for (uint i; i < _outputToLp1Route.length; ++i) {
            outputToLp1Route.push(_outputToLp1Route[i]);
        }

        stable = ISolidlyPair(asset()).stable();
    }


    /*********************** Compound Strategy ************************************************************************
     * Swap all reward tokens to WETH and swap half/half WETH token to both LP token0 & token1, Add liquidity to LP token
     ***********************************************************************************************************************/

    function _compound() private returns (uint256) {
        _getReinvestReward();
        _convertRewardIntoWETH();
        _convertBonusRewardIntoWETH();

        uint256 wethAmount = IERC20(WETH).balanceOf(address(this));
        uint256 protocolFee = (wethAmount * (feeOnReward)) / (BIPS_DIVISOR);
        uint256 reinvestFee = (wethAmount * (feeOnCompounder)) / (BIPS_DIVISOR);

        IERC20(WETH).safeTransfer(feeTreasury, protocolFee);
        IERC20(WETH).safeTransfer(msg.sender, reinvestFee);

        uint256 liquidity = _convertWETHToDepositToken(wethAmount - reinvestFee - protocolFee);

        return liquidity;
    }

    function _convertRewardIntoWETH() private {
        // Variable reward Super farm strategy
        uint256 rewardBal;

        if (address(poolRewardToken) != address(WETH)) {
            rewardBal = poolRewardToken.balanceOf(address(this));
            if (rewardBal > 0) {
                _convertExactTokentoToken(outputToNativeRoute, rewardBal);
            }
        }
    }

    function _convertBonusRewardIntoWETH() private {
        uint256 rewardLength = bonusRewardTokens.length;

        if (rewardLength > 0) {
            // Variable reward Super farm strategy
            uint256 rewardBal;

            for (uint256 i; i < rewardLength; i++) {
                if (address(bonusRewardTokens[i]) != address(WETH)) {
                    rewardBal = bonusRewardTokens[i].balanceOf(address(this));
                    if (rewardBal > 0) {
                        _convertExactTokentoToken(outputToNativeRoute, rewardBal);
                    }
                }
            }
        }
    }

    function _convertWETHToDepositToken(uint256 amount)
        private
        returns (uint256)
    {
        require(amount > 0, "#<0");
        uint256 amountIn = amount / 2;
        address depositToken = asset();
        address lpToken0 = ISolidlyPair(address(depositToken)).token0();
        address lpToken1 = ISolidlyPair(address(depositToken)).token1();
        
        // swap to token0
        uint256 amountOutToken0 = amountIn;
        // Check if lpToken0 equal to WETH
        if (lpToken0 != (WETH)) {
            amountOutToken0 = _convertExactTokentoToken(outputToLp0Route, amountIn);
        }

        // swap to token1
        uint256 amountOutToken1 = amount - amountIn;
        // Check if lpToken1 equal to WETH
        if (lpToken1 != (WETH)) {
            amountOutToken1 = _convertExactTokentoToken(outputToLp1Route, amountIn);
        }

        // Add liquidity
        (, , uint256 liquidity) = router.addLiquidity(lpToken0, lpToken1, stable, amountOutToken0, amountOutToken1, 1, 1, address(this), block.timestamp + 1200);

        return liquidity;
    }

    function _convertExactTokentoToken(ISolidlyRouter.Route[] memory route, uint256 amount)
        private
        returns (uint256)
    {
        uint256[] memory amountsOutToken = router.getAmountsOut(amount, route);
        uint256 amountOutToken = amountsOutToken[amountsOutToken.length - 1];
        uint256[] memory amountOut = router.swapExactTokensForTokens(amount, amountOutToken, route, address(this), block.timestamp + 1200);

        uint256 swapAmount = amountOut[amountOut.length - 1];

        return swapAmount;
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
        __BaseVaultInit(
            _asset,
            name_,
            symbol_,
            _owner,
            _governor
        );
        __UUPSUpgradeable_init();
    }
}        