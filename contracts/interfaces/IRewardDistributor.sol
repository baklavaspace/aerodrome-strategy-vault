// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IRewardDistributor {

    function rewardToken() external view returns (address);

    function trackerInfo(uint256 _tid) external view returns (
        uint256 lastDistributionTime, 
        address rewardTracker, 
        uint256 allocPoint
    );

    function getRewardTrackerLength() external view returns (uint256);
    
    function tokensPerInterval() external view returns (uint256);
    
    function pendingRewards(address _rewardTracker) external view returns (uint256);

    function distribute(address _rewardTracker) external returns (uint256);
}