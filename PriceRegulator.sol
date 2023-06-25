// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title Price stabilizing Strategy
 * @notice Regulating and stabilizing strategy for stablecoins
 * @author 
 */

import "./GovernableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IStarLinkSatellite.sol";

contract PriceStabilizerUpgradeable is GovernableUpgradeable {
    address public slsToken;

    uint256 public priceUpperBound; // in resolution
    uint256 public priceLowerBound; // in resolution

    uint256 private constant RESOLUTION_PRICE = 10 ** 9;

    uint256 public antiWhalePercentage;

    modifier onlyStarLinkSatellite() {
        require(msg.sender == slsToken, "not GSLS called");
        _;
    }

    function PriceStabilizer_init(uint256 _upper, uint256 _lower) external initializer {
        __PriceStabilizer_init(_upper, _lower);
    }

    function __PriceStabilizer_init(uint256 _upper, uint256 _lower) internal onlyInitializing {
        __Governable_init();

        priceUpperBound = _upper;
        priceLowerBound = _lower;
    }

    function sqrt(uint x) public pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function getCurPriceInResolution() public view returns (uint256) {
        IUniswapV2Pair _pair = IUniswapV2Pair(IStarLinkSatellite(slsToken).uniswapV2Pair());

        (uint112 r1, uint112 r2) = getPairReservesNotBySort();

        uint8 decimal1;
        uint8 decimal2;

        {
            ERC20 _token1 = ERC20(_pair.token0());
            ERC20 _token2 = ERC20(_pair.token1());
            
            decimal1 = _token1.decimals();
            decimal2 = _token2.decimals();

            require(slsToken == address(_token1) || slsToken == address(_token2), "Invalid Token");

            if (slsToken != address(_token1)) {
                uint8 tt = decimal1;
                decimal1 = decimal2;
                decimal2 = tt;
            }
        }

        if (decimal1 >= decimal2) {
            return RESOLUTION_PRICE * (r2 * (10 ** (decimal1 - decimal2))) / r1;
        } else {
            return RESOLUTION_PRICE * r2 / (r1 * (10 ** (decimal2 - decimal1)));
        }
    }

    function getMaxSellAmount() public view returns (uint256) {
        uint256 curPriceRes = getCurPriceInResolution();
        if (curPriceRes <= priceLowerBound) return 0;

        (uint112 r1, ) = getPairReservesNotBySort();

        uint256 s1 = sqrt(curPriceRes * RESOLUTION_PRICE * RESOLUTION_PRICE / priceLowerBound);
        return r1 * (s1 - RESOLUTION_PRICE) * 10000 / (RESOLUTION_PRICE * 9975);
    }

    function getMaxBuyAmount() public view returns (uint256) {
        uint256 curPriceRes = getCurPriceInResolution();
        if (curPriceRes >= priceUpperBound) return 0;

        (uint112 r1, ) = getPairReservesNotBySort();

        uint256 s1 = sqrt(curPriceRes * RESOLUTION_PRICE * RESOLUTION_PRICE / priceUpperBound);
        return r1 * (RESOLUTION_PRICE - s1) * 10000 / (RESOLUTION_PRICE * 9975);
    }

    function innerSell(uint256 _tokenAmount) internal {
        IUniswapV2Router02 _router = IUniswapV2Router02(IStarLinkSatellite(slsToken).uniswapV2Router());
        IUniswapV2Pair _pair = IUniswapV2Pair(IStarLinkSatellite(slsToken).uniswapV2Pair());
        address _token1 = _pair.token0();
        address _token2 = _pair.token1();

        address[] memory path = new address[](2);
        path[0] = slsToken;
        path[1] = _token1 == slsToken? _token2: _token1;
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_tokenAmount, 0, path, address(this), block.timestamp);
    }

    function innerBuy(uint256 _pairedTokenAmount) internal {
        IUniswapV2Router02 _router = IUniswapV2Router02(IStarLinkSatellite(slsToken).uniswapV2Router());
        IUniswapV2Pair _pair = IUniswapV2Pair(IStarLinkSatellite(slsToken).uniswapV2Pair());
        address _token1 = _pair.token0();
        address _token2 = _pair.token1();

        address[] memory path = new address[](2);
        path[0] = _token1 == slsToken? _token2: _token1;
        path[1] = slsToken;
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_pairedTokenAmount, 0, path, address(this), block.timestamp);
    }

    function regulateBuy(uint256 _amount) external onlyStarLinkSatellite returns (uint256) {
        (uint256 _busdAmountToBeRegulated, uint256 _tokenAmountToBeRegulated) = getCompensationWhenBuy(_amount); // StarLinkSatellite token amount

        if (_busdAmountToBeRegulated > 0) { // hit lowest boundary
            IUniswapV2Pair _pair = IUniswapV2Pair(IStarLinkSatellite(slsToken).uniswapV2Pair());
            address _token1 = _pair.token0();
            address _token2 = _pair.token1();

            address pairedToken = _token1 == slsToken? _token2: _token1;
            if (ERC20(pairedToken).balanceOf(address(this)) >= _busdAmountToBeRegulated) {
                ERC20(pairedToken).transfer(address(_pair), _busdAmountToBeRegulated);
            }
        }

        if (_tokenAmountToBeRegulated > 0) { // hit highest boundary
            address _pair = IStarLinkSatellite(slsToken).uniswapV2Pair();
            if (ERC20(slsToken).balanceOf(address(this)) >= _tokenAmountToBeRegulated) {
                ERC20(slsToken).transfer(_pair, _tokenAmountToBeRegulated);
            }
        }

        return _amount;
    }

    function regulateSell(uint256 _amount) external onlyStarLinkSatellite returns (uint256) {
        (uint112 r1, uint112 r2) = getPairReservesNotBySort();

        if (r1 == 0 || r2 == 0) return _amount;

        uint256 maxAmount = antiWhalePercentage * ERC20(slsToken).balanceOf(IStarLinkSatellite(slsToken).uniswapV2Pair()) / 10000;
        require(maxAmount == 0 || _amount <= maxAmount, "reached maximum limit");

        (uint256 _pairedTokenAmountToBeRegulated, uint256 _tokenAmountToBeRegulated) = getCompensationWhenSell(_amount); // Paired token amount (BUSD) for buy, StarLinkSatellite token amount for sell

        if (_pairedTokenAmountToBeRegulated > 0) { // hit lowest boundary
            innerBuy(_pairedTokenAmountToBeRegulated);
        }

        if (_tokenAmountToBeRegulated > 0) { // hit highest boundary
            innerSell(_tokenAmountToBeRegulated);
        }
        return _amount;
    }

    function getPairReservesNotBySort() public view returns (uint112 , uint112) {
        IUniswapV2Pair _pair = IUniswapV2Pair(IStarLinkSatellite(slsToken).uniswapV2Pair());

        (uint112 r1, uint112 r2, ) = _pair.getReserves();

        address tk0 = _pair.token0();
        address tk1 = _pair.token1();

        require(slsToken == tk0 || slsToken == tk1, "Invalid token");
        
        if (slsToken != tk0) {
            uint112 tt = r1;
            r1 = r2;
            r2 = tt;
        }

        return (r1, r2);
    }

    function updateAntiwhalePercentage(uint256 _maxAntiWhalePercentage) external onlyGovernor {
        antiWhalePercentage = _maxAntiWhalePercentage;
    }

    function updatePriceRange(uint256 _upperInResolution, uint256 _lowerInResolution) external onlyGovernor {
        priceUpperBound = _upperInResolution;
        priceLowerBound = _lowerInResolution;
    }

    function updateTargetToken(address _token) external onlyGovernor {
        slsToken = _token;

        ERC20(slsToken).approve(IStarLinkSatellite(slsToken).uniswapV2Router(), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

        IUniswapV2Pair _pair = IUniswapV2Pair(IStarLinkSatellite(slsToken).uniswapV2Pair());
        address _token1 = _pair.token0();
        address _token2 = _pair.token1();

        address pairedToken = _token1 == slsToken? _token2: _token1;
        ERC20(pairedToken).approve(IStarLinkSatellite(slsToken).uniswapV2Router(), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }

    function withdraw(address _erc20, address _to, uint256 _amount) external onlyGovernor {
        ERC20(_erc20).transfer(_to, _amount);
    }

    function swapBusdForStarLinkSatellite(address to, uint256 amountIn, uint256 amountOutMin) external onlyStarLinkSatellite {
        IUniswapV2Router02 _router = IUniswapV2Router02(IStarLinkSatellite(slsToken).uniswapV2Router());
        address[] memory path;

        {
            IUniswapV2Pair _pair = IUniswapV2Pair(IStarLinkSatellite(slsToken).uniswapV2Pair());
            address _token1 = _pair.token0();
            address _token2 = _pair.token1();

            path = new address[](2);
            path[0] = _token1 == slsToken? _token2: _token1;
            path[1] = slsToken;
        }

        {
            uint256 oldBalance = ERC20(path[0]).balanceOf(address(this));
            ERC20(path[0]).transferFrom(to, address(this), amountIn);
            uint256 newBalance = ERC20(path[0]).balanceOf(address(this));

            amountIn = newBalance - oldBalance;
            require(amountIn > 0, "Transfer error of BUSD");
        }

        if (false)
        {
            /**************************************************
            ** when price is enabled, all BUSD is sunk here ***
            **************************************************/

            uint256 curPrice = getCurPriceInResolution();

            if (IStarLinkSatellite(slsToken).priceStabilizingEnabled() && curPrice >= priceLowerBound && curPrice <= priceUpperBound) {
                (uint112 r1, uint112 r2) = getPairReservesNotBySort();
                uint256 slsTokenToSend = amountIn * uint256(r1) * 9975 / ((uint256(r2) + amountIn) * 10000);

                if (ERC20(path[1]).balanceOf(address(this)) >= slsTokenToSend) {
                    ERC20(path[1]).transfer(to, slsTokenToSend);
                    return;
                }
            }

            _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, block.timestamp);
        }
        else
        {
            /**************************************************
            ** when price is enabled, all BUSD is sunk here ***
            **************************************************/

            (uint112 r1, uint112 r2) = getPairReservesNotBySort();
            uint256 amn1 = amountIn / 2;
            uint256 slsTokenToSend = (amountIn - amn1) * uint256(r1) * 9975 / ((uint256(r2) + amountIn - amn1) * 10000);

            if (IStarLinkSatellite(slsToken).priceStabilizingEnabled()) {
                if (ERC20(path[1]).balanceOf(address(this)) >= slsTokenToSend) {
                    ERC20(path[1]).transfer(to, slsTokenToSend);
                    if (amountOutMin >= slsTokenToSend) {
                        amountOutMin -= slsTokenToSend;
                    } else {
                        amountOutMin = 0;
                    }
                } else {
                    amn1 = amountIn;
                }
            } else {
                amn1 = amountIn;
            }

            _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amn1, amountOutMin, path, to, block.timestamp);
            _monitorEnable();
        }
    }

    function swapStarLinkSatelliteForBusd(address to, uint256 amountIn, uint256 amountOutMin) external onlyStarLinkSatellite {
        IUniswapV2Router02 _router = IUniswapV2Router02(IStarLinkSatellite(slsToken).uniswapV2Router());
        IUniswapV2Pair _pair = IUniswapV2Pair(IStarLinkSatellite(slsToken).uniswapV2Pair());
        address _token1 = _pair.token0();
        address _token2 = _pair.token1();

        address[] memory path = new address[](2);
        path[0] = slsToken;
        path[1] = _token1 == slsToken? _token2: _token1;

        uint256 oldBalance = ERC20(path[0]).balanceOf(address(this));
        ERC20(path[0]).transferFrom(to, address(this), amountIn);
        uint256 newBalance = ERC20(path[0]).balanceOf(address(this));

        amountIn = newBalance - oldBalance;
        require(amountIn > 0, "Transfer error of GSLS");

        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, block.timestamp);
    }

    function _monitorEnable() private {
        (uint112 r1, uint112 r2) = getPairReservesNotBySort();

        if (r1 == 0 || r2 == 0) return;

        uint256 dotPriceAfterSell = getPriceAfterSell(0);

        if (dotPriceAfterSell >= priceUpperBound && !IStarLinkSatellite(slsToken).priceStabilizingEnabled()) {
            IStarLinkSatellite(slsToken).enablePriceStabilizing(true);
        }
    }

    function swapAndLiquify(uint256 amount) external {
        if (amount == 0) return;

        uint256 half = amount / 2;
        uint256 otherHalf = amount - half;

        IUniswapV2Pair _pair = IUniswapV2Pair(IStarLinkSatellite(slsToken).uniswapV2Pair());
        address _token1 = _pair.token0();
        address _token2 = _pair.token1();

        address pairedToken = (_token1 == slsToken)? _token2: _token1;

        uint256 tmpBalance = IERC20(pairedToken).balanceOf(address(this));

        innerSell(half);

        uint256 balanceToTransfer = IERC20(pairedToken).balanceOf(address(this)) - tmpBalance;
        _addLiquidity(otherHalf, balanceToTransfer);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 busdAmount) private {
        IUniswapV2Router02 _router = IUniswapV2Router02(IStarLinkSatellite(slsToken).uniswapV2Router());

        IUniswapV2Pair _pair = IUniswapV2Pair(IStarLinkSatellite(slsToken).uniswapV2Pair());
        address _token1 = _pair.token0();
        address _token2 = _pair.token1();

        address pairedToken = (_token1 == slsToken)? _token2: _token1;

        // add the liquidity
        _router.addLiquidity(
            slsToken,
            pairedToken,
            tokenAmount,
            busdAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function getPriceAfterSell(uint256 _amount) public view returns (uint256) {
        (uint112 r1, uint112 r2) = getPairReservesNotBySort();
        uint256 realSellAmount = _amount * 9975 / 10000;
        uint256 dotPriceAfterSell = RESOLUTION_PRICE * uint256(r1) * uint256(r2) / (uint256(r1 + realSellAmount) * uint256(r1 + realSellAmount));
        return dotPriceAfterSell;
    }

    function getPriceAfterBuy(uint256 _amount) public view returns (uint256) {
        (uint112 r1, uint112 r2) = getPairReservesNotBySort();
        uint256 realBuyAmount = _amount * 9975 / 10000;
        uint256 dotPriceAfterBuy = RESOLUTION_PRICE * uint256(r1) * uint256(r2) / (uint256(r1 - realBuyAmount) * uint256(r1 - realBuyAmount));
        return dotPriceAfterBuy;
    }

    function getCompensationWhenSell(uint256 _amount) public view returns (uint256, uint256) {
        (uint112 r1, uint112 r2 ) = getPairReservesNotBySort();

        uint256 dotPriceAfterSell = getPriceAfterSell(_amount);

        if (dotPriceAfterSell < priceLowerBound) {
            uint256 tmp = sqrt(uint256(r1) * uint256(r2) * RESOLUTION_PRICE / priceLowerBound);
            if (tmp <= _amount) return (0, 0);
            if (uint256(r1) + _amount < tmp) return (0, 0);

            return (uint256(r2) * (uint256(r1) - (tmp - _amount)) / (tmp - _amount), 0);
        } else if (dotPriceAfterSell > priceUpperBound) {
            uint256 tmp = sqrt(uint256(r1) * uint256(r2) * RESOLUTION_PRICE / priceUpperBound);
            if (_amount >= uint256(r1)) return (0, 0);
            if (tmp < uint256(r1) + _amount) return (0, 0);
            return (0, tmp - (uint256(r1) + _amount));
        } else {
            return (0, 0);
        }
    }

    function getCompensationWhenBuy(uint256 _amount) public view returns (uint256, uint256) {
        (uint112 r1, uint112 r2) = getPairReservesNotBySort();

        uint256 dotPriceAfterBuy = getPriceAfterBuy(_amount);

        if (dotPriceAfterBuy < priceLowerBound) {
            if (uint256(r1) <= _amount) return (0, 0);
            uint256 tmp = priceLowerBound * (uint256(r1) - _amount) / RESOLUTION_PRICE;
            uint256 b = uint256(r2) * _amount / (uint256(r1) - _amount);
            if (tmp < uint256(r2) + b) return (0, 0);
            return (tmp - (uint256(r2) + b), 0);
        } else if (dotPriceAfterBuy > priceUpperBound) {
            if (uint256(r1) <= _amount) return (0, 0);
            uint256 b = uint256(r2) * _amount / (uint256(r1) - _amount);
            uint256 tmp = (uint256(r2) + b) * RESOLUTION_PRICE / priceUpperBound;
            if (tmp + _amount < uint256(r1)) return (0, 0);
            return (0, tmp - (uint256(r1) - _amount));
        } else {
            return (0, 0);
        }
    }
}
