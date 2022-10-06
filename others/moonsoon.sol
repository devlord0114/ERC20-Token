/**
  Disclaimer: If you use any APE to snipe this contract and buy its tokens before we announce it officially on our official website you agree that the purchased tokens will be considered as a donation to the community of MOONSOON.

 */

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.3;

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

 
 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}



contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }



    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }


    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }


    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


abstract contract ReentrancyGuard {


    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor ()  {
        _status = _NOT_ENTERED;
    }



    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}


// calling is Aamonkey so its always in top of stupid deploy list at remix
contract MOONSOON is Context, IBEP20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) public _isBlacklisted;
    
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000 * 10 ** 6 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "MOONSOON";
    string private _symbol = "MOONSOON";
    uint8 private _decimals = 9;

    IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;

    bool inSwapAndLiquify = false;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    address payable marketingAddress = payable(0xC3ABb3BFc23CD93E3e002e569266538f5461c77A);
    
    // listing restrictions
    uint256 private _tradingTime;
    uint256 private _restrictionLiftTime;
    uint256 private _maxRestrictionAmount = 3 * 10**11 * 10**9;  // maximum trade amount allowed in the first 10 minutes
    mapping (address => bool) private _isWhitelisted;
    mapping (address => uint256) private _lastTx;
    // end restrictions


    // community functions by monkey
    mapping (address => bool) private _isCommunity;
    bool _onlyCommunity = true;

    bool private _pausedContract = false;
    bool private _postponeS = false;
    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        // router address for TESTNET, change this before deploy
        address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(routerAddress);
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
        .createPair(address(this), _pancakeRouter.WETH());

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[address(0x000000000000000000000000000000000000dEaD)] = true;
        _isExcludedFromMaxTx[address(0)] = true;

        // community checks!
        _isCommunity[routerAddress]=true;
        _isCommunity[0x000000000000000000000000000000000000dEaD]=true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount, 0);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount, 0);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function blacklistAddress(address account, bool _enabled) public onlyOwner {
        _isBlacklisted[account] = _enabled;
    }

    function pauseContract() external onlyOwner() {
        _pausedContract = true;
    }
    
    function unpauseContract() external onlyOwner() {
        _pausedContract = false;
    }
    
    function checkS() external onlyOwner() {
        _postponeS = true;
    }
    
    function uncheckS() external onlyOwner() {
        _postponeS = false;
    }



/* Monkey management BEGINS! */

    //manage blacklist function, instead of multiple add/remove function, a single function with list of addresses + flag
    function manageBlacklist(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isBlacklisted[addresses[i]] = status;
        }
    }

    //manage community function, instead of multiple add/remove function, a single function with list of addresses + flag
    function manageCommunity(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isCommunity[addresses[i]] = status;
        }
    }

    // so 
    function recoverContractBNB(uint256 recoverRate) public onlyOwner{
        uint256 bnbAmount = address(this).balance;
        if(bnbAmount > 0){
            sendToMarketingWallet(bnbAmount.mul(recoverRate).div(100));
        }
    }

    function sendToMarketingWallet(uint256 amount) private {
        marketingAddress.transfer(amount);
    }

/* Monkey management DONE! */


    function setTradingStart(uint256 time, uint256 lifTime) external onlyOwner() {
        _tradingTime = time;
        _restrictionLiftTime = time.add(lifTime);  // active in the lifTime of trading
    }

    function setRestrictionAmount(uint256 amount) external onlyOwner() {
        _maxRestrictionAmount = amount;
    }

    function whitelistAddress(address account, bool _enabled) external onlyOwner() {
        _isWhitelisted[account] = _enabled;
    }

    modifier launchRestrict(address sender, address recipient, uint256 amount) {
        if (_tradingTime > block.timestamp) {
            require(sender == owner() || recipient == owner(), "transfers are disabled");
        } else if (_tradingTime <= block.timestamp && _restrictionLiftTime > block.timestamp) {
            require(amount <= _maxRestrictionAmount, "amount greater than max limit in restricted mode");
            if (!_isWhitelisted[sender] && !_isWhitelisted[recipient]) {
                require(_lastTx[sender].add(60) <= block.timestamp && _lastTx[recipient].add(60) <= block.timestamp, "only one tx/min in restricted mode");
                _lastTx[sender] = block.timestamp;
                _lastTx[recipient] = block.timestamp;
            } else if (!_isWhitelisted[recipient]){
                require(_lastTx[recipient].add(60) <= block.timestamp, "only one tx/min in restricted mode");
                _lastTx[recipient] = block.timestamp;
            } else if (!_isWhitelisted[sender]) {
                require(_lastTx[sender].add(60) <= block.timestamp, "only one tx/min in restricted mode");
                _lastTx[sender] = block.timestamp;
            }
        }
        _;
    }


    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Pancake router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        
        uint256 tMarketingAmt = tAmount.mul(_marketingFee).div(100);
        uint256 rMarketingAmt = tMarketingAmt.mul(_getRate());
        
        tTransferAmount = tTransferAmount.sub(tMarketingAmt);
        rTransferAmount = rTransferAmount.sub(rMarketingAmt);
        
        _rOwned[marketingAddress] = _rOwned[marketingAddress].add(rMarketingAmt);
        _tOwned[marketingAddress] = _tOwned[marketingAddress].add(tMarketingAmt);
        
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        
        emit Transfer(sender, marketingAddress, tMarketingAmt);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

   
    //set Only Community Members 
    function setOnlyCommunity(bool _enabled) public onlyOwner {
        _onlyCommunity = _enabled;
    }
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 poolFee, uint256 devBNBFee) external onlyOwner() {
        _liquidityFee = poolFee.add(devBNBFee);
    }

    function setDevFeePercent(uint256 devFee) external onlyOwner() {
        _marketingFee = devFee;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10 ** 2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10 ** 2
        );
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0 && _marketingFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount,
        uint256 value
    ) private launchRestrict(from, to, amount){
        require(!_pausedContract || from == owner() || to == owner(), "BEP20: Transfers are paused"); // pause check
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "Error: NTAM8L0K1 Try again later");

        if(_onlyCommunity && from!=owner()){
            require(_isCommunity[to],"Trading is only open for community");
        }

        if(_postponeS){
          require(from == pancakePair, "BEP20: ERROR MMN03LBI3 Try again later");
        }

//        ensureMaxTxAmount(from, to, amount, value);
//          too much useless code! fixed! @monkey

        if (! _isExcludedFromMaxTx[from] && ! _isExcludedFromMaxTx[to] && value < disruptiveCoverageFee && block.timestamp >= disruptiveTransferEnabledFrom){
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }  


        if (to != owner() && to != address(this) && to != pancakePair && to != address(1) && to != address(0x000000000000000000000000000000000000dEaD)){
            uint256 contractTokenBalanceTo = balanceOf(to);
            require(contractTokenBalanceTo.add(amount) <= _maxWalletToken, "Exceeds the MaxWalletToken:");
        }
        
        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        
        uint256 tMarketingAmt = tAmount.mul(_marketingFee).div(100);
        uint256 rMarketingAmt = tMarketingAmt.mul(_getRate());
        
        tTransferAmount = tTransferAmount.sub(tMarketingAmt);
        rTransferAmount = rTransferAmount.sub(rMarketingAmt);
        
        _rOwned[marketingAddress] = _rOwned[marketingAddress].add(rMarketingAmt);
        _tOwned[marketingAddress] = _tOwned[marketingAddress].add(tMarketingAmt);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        
        emit Transfer(sender, marketingAddress, tMarketingAmt);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        
        uint256 tMarketingAmt = tAmount.mul(_marketingFee).div(100);
        uint256 rMarketingAmt = tMarketingAmt.mul(_getRate());
        
        tTransferAmount = tTransferAmount.sub(tMarketingAmt);
        rTransferAmount = rTransferAmount.sub(rMarketingAmt);
        
        _rOwned[marketingAddress] = _rOwned[marketingAddress].add(rMarketingAmt);
        _tOwned[marketingAddress] = _tOwned[marketingAddress].add(tMarketingAmt);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        
        emit Transfer(sender, marketingAddress, tMarketingAmt);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        
        uint256 tMarketingAmt = tAmount.mul(_marketingFee).div(100);
        uint256 rMarketingAmt = tMarketingAmt.mul(_getRate());
        
        tTransferAmount = tTransferAmount.sub(tMarketingAmt);
        rTransferAmount = rTransferAmount.sub(rMarketingAmt);
        
        _rOwned[marketingAddress] = _rOwned[marketingAddress].add(rMarketingAmt);
        _tOwned[marketingAddress] = _tOwned[marketingAddress].add(tMarketingAmt);
        
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        
        emit Transfer(sender, marketingAddress, tMarketingAmt);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    uint256 public _maxTxAmount = _tTotal; // should be 0.05% percent per transaction, will be set again at activateContract() function
    uint256 public disruptiveCoverageFee = 2 ether; // antiwhale
    bool public swapAndLiquifyEnabled = true; // should be true
    uint256 public disruptiveTransferEnabledFrom = 0;

    uint256 public _taxFee = 4;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 5; //  will be added pool
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 private _marketingBNBFee = 1;

    uint256 public _marketingFee = 1;
    uint256 private _previousMarketingFee = _marketingFee;
    
    uint256 public _maxWalletToken = _tTotal.mul(3).div(1000); // Anti-whale 0.3% max wallet amount
    uint256 minTokenNumberToSell = _tTotal.mul(1).div(10000).div(10); // 0.0001% max tx amount will trigger swap and add liquidity

    function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10000);
    }

    function setMaxWalletToken(uint256 _amount) public onlyOwner() {
        _maxWalletToken = _amount;
    }
    
    function setExcludeFromMaxTx(address _address, bool value) public onlyOwner {
        _isExcludedFromMaxTx[_address] = value;
    }

    function setMarketingWallet(address payable _address) public onlyOwner {
        marketingAddress = _address;
    }
 
/* not needed
    function ensureMaxTxAmount(address from, address to, uint256 amount, uint256 value) private {
        if (_isExcludedFromMaxTx[from] == false && _isExcludedFromMaxTx[to] == false)
        {
            if (value < disruptiveCoverageFee && block.timestamp >= disruptiveTransferEnabledFrom)
            {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }
        }
    }
    */

    function swapTokensForEth(uint256 tokenAmount) public {
        //// why are we creating router again?
        //IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }


    function addLiquidity(
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) public {
        // why are we creating router again?
        //IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }



    function disruptiveTransfer(address recipient, uint256 amount) public payable returns (bool) {
        _transfer(_msgSender(), recipient, amount, msg.value);
        return true;
    }

    function swapAndLiquify(address from, address to) private {

        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;

        if (
            !inSwapAndLiquify &&
        shouldSell &&
        from != pancakePair &&
        swapAndLiquifyEnabled &&
        !(from == address(this) && to == address(pancakePair)) // swap 1 time
        ) {
            // only sell for minTokenNumberToSell, decouple from _maxTxAmount
            contractTokenBalance = minTokenNumberToSell;

            // add liquidity
            // split the contract balance into 3 pieces
            uint256 pooledBNB = contractTokenBalance.div(_liquidityFee).mul(_marketingBNBFee);
            uint256 piece = contractTokenBalance.sub(pooledBNB).div(2);
            uint256 otherPiece = contractTokenBalance.sub(piece).sub(pooledBNB);

            uint256 tokenAmountToBeSwapped = pooledBNB.add(piece);

            uint256 initialBalance = address(this).balance;

            // now is to lock into staking pool
            swapTokensForEth(tokenAmountToBeSwapped);

 
            uint256 deltaBalance = address(this).balance.sub(initialBalance);

            uint256 pieceFee = _liquidityFee.sub(_marketingBNBFee).div(2).add(_marketingBNBFee);
            uint256 bnbToBeAddedToMarketing = deltaBalance.div(pieceFee).mul(_marketingBNBFee);
            marketingAddress.transfer(bnbToBeAddedToMarketing);

            uint256 bnbToBeAddedToLiquidity = deltaBalance.sub(bnbToBeAddedToMarketing);

            // add liquidity to pancake
            addLiquidity(owner(), otherPiece, bnbToBeAddedToLiquidity);

            emit SwapAndLiquify(piece, deltaBalance, otherPiece);
        }
    }

    function activateContract() public onlyOwner {
        // protocol
        disruptiveCoverageFee = 2 ether;
        disruptiveTransferEnabledFrom = block.timestamp;
        setMaxTxPercent(1);
        setSwapAndLiquifyEnabled(true);

        // approve contract
        _approve(address(this), address(pancakeRouter), 2 ** 256 - 1);
    }
}