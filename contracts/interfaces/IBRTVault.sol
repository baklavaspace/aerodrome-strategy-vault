// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBRTVault is IERC20 {

    function updateRewards() external;

    function deposit(uint256 _assets, address _receiver) external returns (uint256);

    function redeem(uint256 _shares, address _receiver, address _owner) external returns (uint256);

    function compound() external;

    function checkReward() external view returns (uint256);
    
    function totalSupply() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function asset() external view returns (address);
    
    function claimable(address user) external view returns (uint256);

    function userInfo(address account) external view returns (
        uint256 claimableReward,
        uint256 previousCumulatedRewardPerToken
    );
}