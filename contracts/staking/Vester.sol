// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {Governable} from "../common/Governable.sol";
import "../interfaces/IMintable.sol";

contract Vester is IERC20, Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable, Governable {
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public vestingDuration;

    address public esToken;
    address public claimableToken;

    uint256 public override totalSupply;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public cumulativeClaimAmounts;
    mapping (address => uint256) public claimedAmounts;
    mapping (address => uint256) public lastVestingTimes;

    mapping (address => bool) public isHandler;

    event Claim(address receiver, uint256 amount);
    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 claimedAmount, uint256 balance);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**************************************************************
     * Core user functions 
     *************************************************************/
     
    function deposit(uint256 _amount) external nonReentrant {
        _deposit(msg.sender, _amount);
    }

    function depositForAccount(address _account, uint256 _amount) external nonReentrant {
        _validateHandler();
        _deposit(_account, _amount);
    }

    function withdraw() external nonReentrant {
        address account = msg.sender;
        address _receiver = account;
        _claim(account, _receiver);

        uint256 claimedAmount = cumulativeClaimAmounts[account];
        uint256 balance = balances[account];
        uint256 totalVested = balance + (claimedAmount);
        require(totalVested > 0, "Vester: vested amount is zero");

        IERC20(esToken).safeTransfer(_receiver, balance);
        _burn(account, balance);

        delete cumulativeClaimAmounts[account];
        delete claimedAmounts[account];
        delete lastVestingTimes[account];

        emit Withdraw(account, claimedAmount, balance);
    }

    function claim() external nonReentrant returns (uint256) {
        return _claim(msg.sender, msg.sender);
    }

    function claimForAccount(address _account, address _receiver) external nonReentrant returns (uint256) {
        _validateHandler();
        return _claim(_account, _receiver);
    }

    /**************************************************************
     * View functions 
     *************************************************************/

    function claimable(address _account) public view returns (uint256) {
        uint256 amount = cumulativeClaimAmounts[_account] - (claimedAmounts[_account]);
        uint256 nextClaimable = _getNextClaimableAmount(_account);
        return amount + (nextClaimable);
    }

    // function getTotalVested(address _account) public view returns (uint256) {
    //     return balances[_account] + (cumulativeClaimAmounts[_account]);
    // }

    function balanceOf(address _account) public view override returns (uint256) {
        return balances[_account];
    }

    function getVestedAmount(address _account) public view returns (uint256) {
        uint256 balance = balances[_account];
        uint256 cumulativeClaimAmount = cumulativeClaimAmounts[_account];
        return balance + (cumulativeClaimAmount);
    }

    /**************************************************************
     * Internal functions 
     *************************************************************/

    function _mint(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: mint to the zero address");

        totalSupply = totalSupply + (_amount);
        balances[_account] = balances[_account] + (_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: burn from the zero address");

        balances[_account] = balances[_account] - (_amount);  // "Vester: burn amount exceeds balance"
        totalSupply = totalSupply - (_amount);

        emit Transfer(_account, address(0), _amount);
    }

    function _deposit(address _account, uint256 _amount) private {
        require(_amount > 0, "Vester: invalid _amount");

        _claim(_account, _account);

        IERC20(esToken).safeTransferFrom(_account, address(this), _amount);

        _mint(_account, _amount);

        emit Deposit(_account, _amount);
    }

    function _claim(address _account, address _receiver) private returns (uint256) {
        _updateVesting(_account);
        uint256 amount = claimable(_account);
        claimedAmounts[_account] = claimedAmounts[_account] + (amount);
        IERC20(claimableToken).safeTransfer(_receiver, amount);
        emit Claim(_account, amount);
        return amount;
    }

    function _updateVesting(address _account) private {
        uint256 amount = _getNextClaimableAmount(_account);
        lastVestingTimes[_account] = block.timestamp;

        if (amount == 0) {
            return;
        }

        // transfer claimableAmount from balances to cumulativeClaimAmounts
        _burn(_account, amount);
        cumulativeClaimAmounts[_account] = cumulativeClaimAmounts[_account] + (amount);

        IMintable(esToken).burn(amount);
    }

    function _getNextClaimableAmount(address _account) internal view returns (uint256) {
        uint256 balance = balances[_account];
        if (balance == 0) { return 0; }

        uint256 timeDiff = block.timestamp - (lastVestingTimes[_account]);

        uint256 vestedAmount = getVestedAmount(_account);
        uint256 claimableAmount = vestedAmount * (timeDiff) / (vestingDuration);

        if (claimableAmount < balance) {
            return claimableAmount;
        }

        return balance;
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "Vester: forbidden");
    }

    /**************************************************************
     * Empty ERC20 implementation functions 
     *************************************************************/

    // empty implementation, tokens are non-transferrable
    function transfer(address /* recipient */, uint256 /* amount */) public override returns (bool) {
        revert("Vester: non-transferrable");
    }

    // empty implementation, tokens are non-transferrable
    function allowance(address /* owner */, address /* spender */) public view virtual override returns (uint256) {
        return 0;
    }

    // empty implementation, tokens are non-transferrable
    function approve(address /* spender */, uint256 /* amount */) public virtual override returns (bool) {
        revert("Vester: non-transferrable");
    }

    // empty implementation, tokens are non-transferrable
    function transferFrom(address /* sender */, address /* recipient */, uint256 /* amount */) public virtual override returns (bool) {
        revert("Vester: non-transferrable");
    }

    /**************************************************************
     * Only Owner functions 
     *************************************************************/
    function _authorizeUpgrade(address) internal override onlyRole(OWNER_ROLE) {}

    // to help users who accidentally send their tokens to this contract
    function recoverToken(address _token, address _account, uint256 _amount) external onlyRole(OWNER_ROLE) {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function setHandler(address _handler, bool _isActive) external onlyRole(OWNER_ROLE) {
        isHandler[_handler] = _isActive;
    }

    function updateVestingDuration(uint256 newVestingDuration) external onlyRole(OWNER_ROLE) {
        vestingDuration = newVestingDuration;
    }

    /*************************************************************
     * Only Operator functions 
     *************************************************************/
    function mintEsToken(uint256 _amount) external nonReentrant onlyRole(OPERATOR_ROLE) {
        IERC20(claimableToken).transferFrom(msg.sender, address(this), _amount);
        IMintable(esToken).mint(msg.sender, _amount);
    }

    /**************************************************************
     * @dev Initialize smart contract functions - only called once
     *************************************************************/
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _vestingDuration,
        address _esToken,
        address _claimableToken,
        address _owner,
        address _governor
    ) public initializer{
        name = _name;
        symbol = _symbol;

        vestingDuration = _vestingDuration;

        esToken = _esToken;
        claimableToken = _claimableToken;
        __Governable_init(_owner, _governor);
        __UUPSUpgradeable_init();
    }
}