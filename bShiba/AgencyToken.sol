/*
         ______ _______ ______   ______ _     _ 
   /\   / _____|_______)  ___ \ / _____) |   | |
  /  \ | /  ___ _____  | |   | | /     | |___| |
 / /\ \| | (___)  ___) | |   | | |      \_____/ 
| |__| | \____/| |_____| |   | | \_____   ___   
|______|\_____/|_______)_|   |_|\______) (___)  
                                                
*/

// SPDX-License-Identifier: GPL-3.0-or-later Or MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function removeMinter(address account) public onlyMinter {
        _removeMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract AgencyToken is ERC20Upgradeable, OwnableUpgradeable, MinterRole {
    using SafeMathUpgradeable for uint256;

    bool public taxEnabled;
    
    uint256 public devFee;
    uint256 public hqFee;
    uint256 public liquidityFee;

    address public devFeeAddress;
    address public hqFeeAddress;
    address public liquidityFeeAddress;

    mapping (address => bool) private _isExcludedFromFee;

    function initialize() public initializer {
        __ERC20_init('Agency Token', 'AGENCY');
        __Ownable_init();

        _addMinter(msg.sender);
        _mint(msg.sender, 2000000 *10**18);

        devFee = 250;
        liquidityFee = 200;
        hqFee = 50;
    }

    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }

    function isExcludedFromFee(address _account) public view returns (bool) {
        return _isExcludedFromFee[_account];
    }

    function setExcludeFromFee(address _account, bool _enable) external onlyOwner() {
        require(_isExcludedFromFee[_account] != _enable, "AGENCY: Duplicate Process of excludeFromFee.");
        _isExcludedFromFee[_account] = _enable;
    }

    function setTaxEnable(bool _enable) external onlyOwner() {
        require(taxEnabled != _enable, "AGENCY: Duplicate Process of setTaxEnable.");
        taxEnabled = _enable;
    }
      
    function setDevFee(uint256 _amount) external onlyOwner() {
        require(_amount <= 500, "AGENCY: devFee cannot exceed 5%.");
        devFee = _amount;
    }
      
    function setHqFee(uint256 _amount) external onlyOwner() {
        require(_amount <= 500, "AGENCY: hqFee cannot exceed 5%.");
        hqFee = _amount;
    }

    function setLiquidityFee(uint256 _amount) external onlyOwner() {
        require(_amount <= 500, "AGENCY: liquidityFee cannot exceed 5%.");
        liquidityFee = _amount;
    }

    function setDevFeeAddress(address _newAddress) external onlyOwner() {
        require(devFeeAddress != _newAddress, "AGENCY: Duplicate Process of devFeeAddress.");
        devFeeAddress = _newAddress;
    }

    function setHqFeeAddress(address _newAddress) external onlyOwner() {
        require(hqFeeAddress != _newAddress, "AGENCY: Duplicate Process of hqFeeAddress.");
        hqFeeAddress = _newAddress;
    }
  
    function setLiquidityFeeAddress(address _newAddress) external onlyOwner() {
        require(liquidityFeeAddress != _newAddress, "AGENCY: Duplicate Process of liquidityFeeAddress.");
        liquidityFeeAddress = _newAddress;
    }
    
    function recoverContractBalance(address _account) external onlyOwner() {
        uint256 recoverBalance = address(this).balance;
        payable(_account).transfer(recoverBalance);
    }
    
    function recoverERC20(IERC20 recoverToken, uint256 tokenAmount, address _recoveryAddress) external onlyOwner() {
        recoverToken.transfer(_recoveryAddress, tokenAmount);
    }

    function _transfer(address from, address to, uint256 amount ) internal virtual override {
        require(from != address(0), "TestLord: transfer from the zero address");
        require(to != address(0), "TestLord: transfer to the zero address");
        require(amount > 0, "TestLord: Transfer amount must be greater than zero");

        bool _isTax = taxEnabled;
        if (_isTax && (_isExcludedFromFee[from] || _isExcludedFromFee[to]))
            _isTax = false;
        
        // on sell transaction
        if(_isTax){
            uint256 devAmount = amount.mul(devFee).div(10000);
            uint256 hqAmount = amount.mul(hqFee).div(10000);
            uint256 liquidityAmount = amount.mul(liquidityFee).div(10000);

            uint256 sendAmount = amount.sub(devAmount).sub(hqAmount).sub(liquidityAmount);
            super._transfer(from, to, sendAmount);
            super._transfer(from, devFeeAddress, devAmount);
            super._transfer(from, hqFeeAddress, hqAmount);
            super._transfer(from, liquidityFeeAddress, liquidityAmount);
        } else {
            super._transfer(from, to, amount); 
        }
    }
    
}