// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

/**
 * @title LS1Types
 * @author Baklava Space
 *
 * @dev Structs used by the FXSwapStrategyVault contract.
 */
library Types {
    /**
     * @dev The parameters used to representing user reward information.
     *
     * @param claimableReward user claimable reward
     * @param previousCumulatedRewardPerToken user previous cumulated reward per token - used to calculate user reward
     */
    struct UserInfo {
        uint256 claimableReward;
        uint256 previousCumulatedRewardPerToken;
    }

    /**
     * @dev The parameters to show vault information.
     *
     * @param  minTokensToReinvest LP Staking contract
     * @param  feeOnReward  staking Farm ID
     * @param  feeOnCompounder  Fee for user help to sent compound tx
     * @param  feeOnWithdrawal  Fee for protocol

     */
    struct StrategySettings {
        uint256 minTokensToReinvest;
        uint256 feeOnReward;
        uint256 feeOnCompounder;
        uint256 feeOnWithdrawal;
    }
}
