// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IMintable {
    function mint(address _account, uint256 _amount) external;
    
    function burn(uint256 _amount) external;
}