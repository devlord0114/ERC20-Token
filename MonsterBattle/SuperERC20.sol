// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract SuperERC20 is Ownable, ERC20 {
    using SafeMath for uint256;

    uint256 public tokenForBosses = 2 * 10**6 * 10**18;

    address public addressForBosses;
    uint256 public sellFeeRate = 1;
    uint256 public buyFeeRate = 1;
    
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        addressForBosses = _msgSender();
    }


    function setTransferFeeRate(uint256 _sellFeeRate, uint256 _buyFeeRate)
        public
        onlyOwner
    {
        require(_sellFeeRate <= 10 && _sellFeeRate >= 0, "sell fee rate must be <= 10");
        require(_buyFeeRate <= 10 && _buyFeeRate >= 0, "buy fee rate must be <= 10");
        sellFeeRate = _sellFeeRate;
        buyFeeRate = _buyFeeRate;
    }

    function setMinTokensBeforeSwap(uint256 _tokenForBosses)
        public
        onlyOwner
    {
        require(_tokenForBosses < 200 * 10**6 * 10**18);
        tokenForBosses = _tokenForBosses;
    }
}