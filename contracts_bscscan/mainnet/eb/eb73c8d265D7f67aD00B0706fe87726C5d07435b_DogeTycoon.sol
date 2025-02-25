//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;


enum Permission {
    ChangeFees,
    Buyback,
    AdjustContractVariables,
    Authorize,
    Unauthorize,
    PauseUnpauseContract,
    BypassPause,
    LockPermissions,
    ExcludeInclude,
    Blacklist
}


/**
 * Allows for contract ownership along with multi-address authorization for different permissions
 */
abstract contract DogeAuth {
    struct PermissionLock {
        bool isLocked;
        uint64 expiryTime;
    }

    address public owner;
    mapping(address => mapping(uint256 => bool)) private authorizations; // uint256 is permission index
    
    uint256 constant NUM_PERMISSIONS = 10; // always has to be adjusted when Permission element is added or removed
    mapping(string => uint256) permissionNameToIndex;
    mapping(uint256 => string) permissionIndexToName;

    mapping(uint256 => PermissionLock) lockedPermissions;

    constructor(address owner_) {
        owner = owner_;
        for (uint256 i; i < NUM_PERMISSIONS; i++) {
            authorizations[owner_][i] = true;
        }

        permissionNameToIndex["ChangeFees"] = uint256(Permission.ChangeFees);
        permissionNameToIndex["Buyback"] = uint256(Permission.Buyback);
        permissionNameToIndex["AdjustContractVariables"] = uint256(Permission.AdjustContractVariables);
        permissionNameToIndex["Authorize"] = uint256(Permission.Authorize);
        permissionNameToIndex["Unauthorize"] = uint256(Permission.Unauthorize);
        permissionNameToIndex["PauseUnpauseContract"] = uint256(Permission.PauseUnpauseContract);
        permissionNameToIndex["BypassPause"] = uint256(Permission.BypassPause);
        permissionNameToIndex["LockPermissions"] = uint256(Permission.LockPermissions);
        permissionNameToIndex["ExcludeInclude"] = uint256(Permission.ExcludeInclude);
        permissionNameToIndex["Blacklist"] = uint256(Permission.Blacklist);

        permissionIndexToName[uint256(Permission.ChangeFees)] = "ChangeFees";
        permissionIndexToName[uint256(Permission.Buyback)] = "Buyback";
        permissionIndexToName[uint256(Permission.AdjustContractVariables)] = "AdjustContractVariables";
        permissionIndexToName[uint256(Permission.Authorize)] = "Authorize";
        permissionIndexToName[uint256(Permission.Unauthorize)] = "Unauthorize";
        permissionIndexToName[uint256(Permission.PauseUnpauseContract)] = "PauseUnpauseContract";
        permissionIndexToName[uint256(Permission.BypassPause)] = "BypassPause";
        permissionIndexToName[uint256(Permission.LockPermissions)] = "LockPermissions";
        permissionIndexToName[uint256(Permission.ExcludeInclude)] = "ExcludeInclude";
        permissionIndexToName[uint256(Permission.Blacklist)] = "Blacklist";
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownership required."); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorizedFor(Permission permission) {
        require(!lockedPermissions[uint256(permission)].isLocked, "Permission is locked.");
        require(isAuthorizedFor(msg.sender, permission), string(abi.encodePacked("Not authorized. You need the permission ", permissionIndexToName[uint256(permission)]))); _;
    }

    /**
     * Authorize address for one permission
     */
    function authorizeFor(address adr, string memory permissionName) public authorizedFor(Permission.Authorize) {
        uint256 permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = true;
        emit AuthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Authorize address for multiple permissions
     */
    function authorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public authorizedFor(Permission.Authorize) {
        for (uint256 i; i < permissionNames.length; i++) {
            uint256 permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = true;
            emit AuthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Remove address' authorization
     */
    function unauthorizeFor(address adr, string memory permissionName) public authorizedFor(Permission.Unauthorize) {
        require(adr != owner, "Can't unauthorize owner");

        uint256 permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = false;
        emit UnauthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Unauthorize address for multiple permissions
     */
    function unauthorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public authorizedFor(Permission.Unauthorize) {
        require(adr != owner, "Can't unauthorize owner");

        for (uint256 i; i < permissionNames.length; i++) {
            uint256 permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = false;
            emit UnauthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorizedFor(address adr, string memory permissionName) public view returns (bool) {
        return authorizations[adr][permissionNameToIndex[permissionName]];
    }

    /**
     * Return address' authorization status
     */
    function isAuthorizedFor(address adr, Permission permission) public view returns (bool) {
        return authorizations[adr][uint256(permission)];
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        address oldOwner = owner;
        owner = adr;
        for (uint256 i; i < NUM_PERMISSIONS; i++) {
            authorizations[oldOwner][i] = false;
            authorizations[owner][i] = true;
        }
        emit OwnershipTransferred(oldOwner, owner);
    }

    /**
     * Get the index of the permission by its name
     */
    function getPermissionNameToIndex(string memory permissionName) public view returns (uint256) {
        return permissionNameToIndex[permissionName];
    }
    
    /**
     * Get the time the timelock expires
     */
    function getPermissionUnlockTime(string memory permissionName) public view returns (uint256) {
        return lockedPermissions[permissionNameToIndex[permissionName]].expiryTime;
    }

    /**
     * Check if the permission is locked
     */
    function isLocked(string memory permissionName) public view returns (bool) {
        return lockedPermissions[permissionNameToIndex[permissionName]].isLocked;
    }

    /*
     *Locks the permission from being used for the amount of time provided
     */
    function lockPermission(string memory permissionName, uint64 time) public virtual authorizedFor(Permission.LockPermissions) {
        uint256 permIndex = permissionNameToIndex[permissionName];
        uint64 expiryTime = uint64(block.timestamp) + time;
        lockedPermissions[permIndex] = PermissionLock(true, expiryTime);
        emit PermissionLocked(permissionName, permIndex, expiryTime);
    }
    
    /*
     * Unlocks the permission if the lock has expired 
     */
    function unlockPermission(string memory permissionName) public virtual {
        require(block.timestamp > getPermissionUnlockTime(permissionName) , "Permission is locked until the expiry time.");
        uint256 permIndex = permissionNameToIndex[permissionName];
        lockedPermissions[permIndex].isLocked = false;
        emit PermissionUnlocked(permissionName, permIndex);
    }

    event PermissionLocked(string permissionName, uint256 permissionIndex, uint64 expiryTime);
    event PermissionUnlocked(string permissionName, uint256 permissionIndex);
    event OwnershipTransferred(address from, address to);
    event AuthorizedFor(address adr, string permissionName, uint256 permissionIndex);
    event UnauthorizedFor(address adr, string permissionName, uint256 permissionIndex);
}

//SPDX-License-Identifier: UNLICENSED

/**
 * ████████████████▀█████████████████████████████████████████████
 * █▄─▄▄▀█─▄▄─█─▄▄▄▄█▄─▄▄─███─▄─▄─█▄─█─▄█─▄▄▄─█─▄▄─█─▄▄─█▄─▀█▄─▄█
 * ██─██─█─██─█─██▄─██─▄█▀█████─████▄─▄██─███▀█─██─█─██─██─█▄▀─██
 * ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▀▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀
 * 
 * NFT Super-Powered Hyperdeflationary Token
 * Hold more than .1% of circ supply to gain unique NFT's.
 * NFT's change buy/sell and NFT drop rates.
 *
 * + Holders get BUSD rewards
 * + Intelligent Buyback system
 * + Dynamic sell ratios
 *
 * for more info: https://dogetycoon.io
 * 
 */
pragma solidity ^0.8.4;
import './DogeAuth.sol';
import './SafeMath.sol';
import './IDividentDistributor.sol';
import './IBEP20.sol';
import './IDEXRouter.sol';
import './IDEXFactory.sol';
import './IDogeTycoonSuperPower.sol';


contract DogeTycoon is IBEP20, DogeAuth {
    using SafeMath for uint256;

    address WBNB;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Doge Tycoon";
    string constant _symbol = "DTY";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10 * 10 ** 9 * (10 ** _decimals); // 10 billion
    uint256 public _maxTxAmount = _totalSupply / 1000; // 0.1%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isBlacklisted;

    uint256 liquidityFee = 150;
    uint256 buybackFee = 300;
    uint256 reflectionFee = 500;
    uint256 marketingFee = 150;
    uint256 totalBuyFee = 1100;
    uint256 totalSellFee = 1600;
    uint256 feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address pancakeV2BNBPair;
    address[] public pairs;

    uint256 public launchedAt;

    uint256 buybackMultiplierNumerator = 125;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public feesOnNormalTransfers = false;

    IDividendDistributor distributor;
    uint256 distributorGas = 500000;

    IDogeTycoonSuperPower nftSuperPower;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 5000; // 0.02%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address _dividentDistributor, address pancakeExchange, address _WBNB, address _nftSuperPower) DogeAuth(msg.sender) {
        WBNB = _WBNB;
        router = IDEXRouter(pancakeExchange);
        pancakeV2BNBPair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        pairs.push(pancakeV2BNBPair);
        distributor = IDividendDistributor(_dividentDistributor);

        nftSuperPower = IDogeTycoonSuperPower(_nftSuperPower);

        address owner_ = msg.sender;

        isFeeExempt[owner_] = true;
        isTxLimitExempt[owner_] = true;
        isDividendExempt[pancakeV2BNBPair] = true;
        isDividendExempt[address(this)] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = owner_;
        marketingFeeReceiver = owner_;

        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, ~uint256(0));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != ~uint256(0)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!isBlacklisted[sender], "Address is blacklisted");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);

        if(shouldSwapBack()){ swapBack(); }

        if(!launched() && recipient == pancakeV2BNBPair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        bool stf = shouldTakeFee(sender, recipient);

        uint256 amountReceived = stf ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        if(stf && !isSell(recipient)){
            nftSuperPower.tryDrop(recipient, _balances[recipient], getCirculatingSupply());
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched()) return false;

        address[] memory liqPairs = pairs;

        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
        }

        return feesOnNormalTransfers;
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(1); }
        if(selling && buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp){ return getMultipliedFee(); }
        return selling ? totalSellFee : totalBuyFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        uint totalFee = totalSellFee;
        uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
        uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
        return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        bool sell = isSell(recipient);
        uint256 feeAmount = amount.mul(getTotalFee(sell)).div(feeDenominator);

        try nftSuperPower.useSuperPowerInTransaction(sender,recipient,sell,amount,feeAmount) returns (uint256 supFeeAmount, bool used) {
            if(supFeeAmount != feeAmount){
                emit SuperPowerUsed(feeAmount, supFeeAmount);
                feeAmount = supFeeAmount;
            }
         } catch Error(string memory e) {
            emit SuperPowerFailed(string(abi.encodePacked("SuperPower failed with error ", e)));
        } catch {
            emit SuperPowerFailed("SuperPower failed without an error message");
        }
        
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }
        
    function isSell(address recipient) internal view returns (bool) {
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (recipient == liqPairs[i]) return true;
        }
        return false;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pancakeV2BNBPair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalBuyFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {

            uint256 amountBNB = address(this).balance.sub(balanceBefore);

            uint256 totalBNBFee = totalBuyFee.sub(dynamicLiquidityFee.div(2));

            uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
            uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
            uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

            try distributor.deposit{value: amountBNBReflection}() {} catch {}
            payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");

            if(amountToLiquify > 0){
                try router.addLiquidityETH{ value: amountBNBLiquidity }(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                ) {
                    emit AutoLiquify(amountToLiquify, amountBNBLiquidity);
                } catch {
                    emit AutoLiquify(0, 0);
                }
            }

            emit SwapBackSuccess(amountToSwap);
        } catch Error(string memory e) {
            emit SwapBackFailed(string(abi.encodePacked("SwapBack failed with error ", e)));
        } catch {
            emit SwapBackFailed("SwapBack failed without an error message from pancakeSwap");
        }
    }

    function triggerBuyback(uint256 amount, bool triggerBuybackMultiplier) external authorizedFor(Permission.Buyback) {
        buyTokens(amount, DEAD);
        if(triggerBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }
    
    function clearBuybackMultiplier() external authorizedFor(Permission.Buyback) {
        buybackMultiplierTriggeredAt = 0;
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        try router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amount }(
            0,
            path,
            to,
            block.timestamp
        ) {
            emit BoughtBack(amount, to);
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Buyback failed with error ", reason)));
        } catch {
            revert("Buyback failed without an error message from pancakeSwap");
        }
    }

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorizedFor(Permission.AdjustContractVariables) {
        require(numerator / denominator <= 3 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        emit Launched(block.number, block.timestamp);
    }

    function setTxLimit(uint256 amount) external authorizedFor(Permission.AdjustContractVariables) {
        require(amount >= _totalSupply / 2000);
        _maxTxAmount = amount;
    }

    function setSuperPower(address superPower) external authorizedFor(Permission.AdjustContractVariables) {
        nftSuperPower = IDogeTycoonSuperPower(superPower);
    }

    function getSuperPower() external view returns (address) {
        address(nftSuperPower);
    }

    function setIsDividendExempt(address holder, bool exempt) external authorizedFor(Permission.ExcludeInclude) {
        require(holder != address(this) && holder != pancakeV2BNBPair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorizedFor(Permission.ExcludeInclude) {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorizedFor(Permission.ExcludeInclude) {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator, uint256 _totalSellFee) external authorizedFor(Permission.AdjustContractVariables) {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalBuyFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
        totalSellFee = _totalSellFee;
        require(totalBuyFee <= feeDenominator / 10, "Buy fee too high");
        require(totalSellFee <= feeDenominator / 5, "Sell fee too high");
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorizedFor(Permission.AdjustContractVariables) {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorizedFor(Permission.AdjustContractVariables) {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorizedFor(Permission.AdjustContractVariables) {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorizedFor(Permission.AdjustContractVariables) {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorizedFor(Permission.AdjustContractVariables) {
        require(gas <= 1000000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pancakeV2BNBPair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function claimDividend() external {
        distributor.claimDividend();
    }
    
    function addPair(address pair) external authorizedFor(Permission.AdjustContractVariables) {
        pairs.push(pair);
    }
    
    function removeLastPair() external authorizedFor(Permission.AdjustContractVariables) {
        pairs.pop();
    }
    
    function setFeesOnNormalTransfers(bool _enabled) external authorizedFor(Permission.AdjustContractVariables) {
        feesOnNormalTransfers = _enabled;
    }
        
    function setIsBlacklisted(address adr, bool blacklisted) external authorizedFor(Permission.Blacklist) {
        isBlacklisted[adr] = blacklisted;
    }

    function setLaunchedAt(uint256 launched_) external authorizedFor(Permission.AdjustContractVariables) {
        launchedAt = launched_;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
    event BoughtBack(uint256 amount, address to);
    event Launched(uint256 blockNumber, uint256 timestamp);
    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);
    event SuperPowerUsed(uint256 feeAmount, uint256 supFeeAmount);
    event SuperPowerFailed(string message);
}

//SPDX-License-Identifier: UNLICENSED

/**
 * ████████████████▀█████████████████████████████████████████████
 * █▄─▄▄▀█─▄▄─█─▄▄▄▄█▄─▄▄─███─▄─▄─█▄─█─▄█─▄▄▄─█─▄▄─█─▄▄─█▄─▀█▄─▄█
 * ██─██─█─██─█─██▄─██─▄█▀█████─████▄─▄██─███▀█─██─█─██─██─█▄▀─██
 * ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▀▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀
 * 
 * NFT Super-Powered Hyperdeflationary Token
 * Hold more than .1% of circ supply to gain unique NFT's.
 * NFT's change buy/sell and NFT drop rates.
 *
 * + Holders get BUSD rewards
 * + Intelligent Buyback system
 * + Dynamic sell ratios
 *
 * for more info: https://dogetycoon.io
 * 
 */
 
pragma solidity ^0.8.2;
/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: UNLICENSED

/**
 * ████████████████▀█████████████████████████████████████████████
 * █▄─▄▄▀█─▄▄─█─▄▄▄▄█▄─▄▄─███─▄─▄─█▄─█─▄█─▄▄▄─█─▄▄─█─▄▄─█▄─▀█▄─▄█
 * ██─██─█─██─█─██▄─██─▄█▀█████─████▄─▄██─███▀█─██─█─██─██─█▄▀─██
 * ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▀▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀
 * 
 * NFT Super-Powered Hyperdeflationary Token
 * Hold more than .1% of circ supply to gain unique NFT's.
 * NFT's change buy/sell and NFT drop rates.
 *
 * + Holders get BUSD rewards
 * + Intelligent Buyback system
 * + Dynamic sell ratios
 *
 * for more info: https://dogetycoon.io
 * 
 */

 
pragma solidity ^0.8.2;
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

//SPDX-License-Identifier: UNLICENSED

/**
 * ████████████████▀█████████████████████████████████████████████
 * █▄─▄▄▀█─▄▄─█─▄▄▄▄█▄─▄▄─███─▄─▄─█▄─█─▄█─▄▄▄─█─▄▄─█─▄▄─█▄─▀█▄─▄█
 * ██─██─█─██─█─██▄─██─▄█▀█████─████▄─▄██─███▀█─██─█─██─██─█▄▀─██
 * ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▀▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀
 * 
 * NFT Super-Powered Hyperdeflationary Token
 * Hold more than .1% of circ supply to gain unique NFT's.
 * NFT's change buy/sell and NFT drop rates.
 *
 * + Holders get BUSD rewards
 * + Intelligent Buyback system
 * + Dynamic sell ratios
 *
 * for more info: https://dogetycoon.io
 * 
 */
 
pragma solidity ^0.8.2;

interface IDEXRouter {
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

//SPDX-License-Identifier: UNLICENSED

/**
 * ████████████████▀█████████████████████████████████████████████
 * █▄─▄▄▀█─▄▄─█─▄▄▄▄█▄─▄▄─███─▄─▄─█▄─█─▄█─▄▄▄─█─▄▄─█─▄▄─█▄─▀█▄─▄█
 * ██─██─█─██─█─██▄─██─▄█▀█████─████▄─▄██─███▀█─██─█─██─██─█▄▀─██
 * ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▀▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀
 * 
 * NFT Super-Powered Hyperdeflationary Token
 * Hold more than .1% of circ supply to gain unique NFT's.
 * NFT's change buy/sell and NFT drop rates.
 *
 * + Holders get BUSD rewards
 * + Intelligent Buyback system
 * + Dynamic sell ratios
 *
 * for more info: https://dogetycoon.io
 * 
 */
 
pragma solidity ^0.8.2;

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function claimDividend() external;
}

//SPDX-License-Identifier: UNLICENSED

/**
 * ████████████████▀█████████████████████████████████████████████
 * █▄─▄▄▀█─▄▄─█─▄▄▄▄█▄─▄▄─███─▄─▄─█▄─█─▄█─▄▄▄─█─▄▄─█─▄▄─█▄─▀█▄─▄█
 * ██─██─█─██─█─██▄─██─▄█▀█████─████▄─▄██─███▀█─██─█─██─██─█▄▀─██
 * ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▀▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀
 * 
 * NFT Super-Powered Hyperdeflationary Token
 * Hold more than .1% of circ supply to gain unique NFT's.
 * NFT's change buy/sell and NFT drop rates.
 *
 * + Holders get BUSD rewards
 * + Intelligent Buyback system
 * + Dynamic sell ratios
 *
 * for more info: https://dogetycoon.io
 * 
 */
 
pragma solidity ^0.8.2;


interface IDogeTycoonSuperPower {
    function calculateSuperPowerOutput (
        uint256 nftDetails, 
        bool isSell, 
        uint256 amount, 
        uint256 currentFee) external pure returns (uint256 newFee, bool used);
    function tryDrop(address sender, uint256 balance, uint256 circulatingSupply) external;
    function useSuperPowerInTransaction(
      address sender, address recipient, bool isSell, uint256 amount,
      uint256 currentFee) external returns (uint256 newFee, bool used);
}

//SPDX-License-Identifier: UNLICENSED

/**
 * ████████████████▀█████████████████████████████████████████████
 * █▄─▄▄▀█─▄▄─█─▄▄▄▄█▄─▄▄─███─▄─▄─█▄─█─▄█─▄▄▄─█─▄▄─█─▄▄─█▄─▀█▄─▄█
 * ██─██─█─██─█─██▄─██─▄█▀█████─████▄─▄██─███▀█─██─█─██─██─█▄▀─██
 * ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▀▀▀▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀
 * 
 * NFT Super-Powered Hyperdeflationary Token
 * Hold more than .1% of circ supply to gain unique NFT's.
 * NFT's change buy/sell and NFT drop rates.
 *
 * + Holders get BUSD rewards
 * + Intelligent Buyback system
 * + Dynamic sell ratios
 *
 * for more info: https://dogetycoon.io
 * 
 */

 
pragma solidity ^0.8.2;
/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

