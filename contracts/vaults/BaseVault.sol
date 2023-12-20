// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Governable} from "../common/Governable.sol";
import {Storage} from "../impl/Storage.sol";

abstract contract BaseVault is Governable, Storage, PausableUpgradeable, ERC4626Upgradeable {
    using Math for uint256;

    uint256 internal constant BIPS_DIVISOR = 10000;

    function __BaseVaultInit(address _asset, string memory _name, string memory _symbol, address _owner, address _governor) internal{
        __ERC4626_init(IERC20Metadata(_asset));
        __ERC20_init(_name, _symbol);
        __Pausable_init();

        __Governable_init(_owner, _governor);
    }

    // ============================= Public functions ================================ //
    /**
     * @dev See {openzeppelin-IERC4626-deposit}.
     */
    function deposit(uint256 _assets, address _receiver)
        public
        virtual
        override
        whenNotPaused
        returns (uint256)
    {
        return super.deposit(_assets, _receiver);
    }

    /**
     * @dev See {openzeppelin-IERC4626-mint}.
     */
    function mint(uint256 _shares, address _receiver)
        public
        override
        whenNotPaused
        returns (uint256)
    {
        revert("disabled");
    }

    /**
     * @dev See {openzeppelin-IERC4626-withdraw}.
     */
    function withdraw(uint256 _assets, address _receiver, address _owner)
        public
        virtual
        override
        returns (uint256)
    {
        revert("disabled");
    }

    /**
     * @dev See {openzeppelin-IERC4626-redeem}.
     */
    function redeem(uint256 _shares, address _receiver, address _owner)
        public
        virtual
        override
        returns (uint256)
    {
        return super.redeem(_shares, _receiver, _owner);
    }


    // ============================= Public view functions ================================ //
    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        uint256 assets = _convertToAssets(shares, Math.Rounding.Floor);
        assets -= (assets * feeOnWithdrawal) / BIPS_DIVISOR;
        return assets;
    }
    
    // View function to override ERC-4626 totalAssets().
    function totalAssets() public view virtual override returns (uint256) {
        uint256 underlying = IERC20(asset()).balanceOf(address(this));
        return underlying + balanceOfPool();
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        return stakingContract.balanceOf(address(this));
    }

    // ============================= Internal functions ================================ //
    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amount of shares.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, rounding)
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from assets to shares) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToAssets} when overriding it.
     */
    function _initialConvertToShares(
        uint256 assets,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 shares) {
        return assets;
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view override returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToShares} when overriding it.
     */
    function _initialConvertToAssets(
        uint256 shares,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 assets) {
        return shares;
    }

    // ============================= Governable functions ================================ //

    function pause() public onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        _unpause();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}