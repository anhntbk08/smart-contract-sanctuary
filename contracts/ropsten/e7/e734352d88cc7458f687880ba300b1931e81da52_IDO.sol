/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity = 0.5.16;

contract Ownable {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "YouSwap: CALLER_IS_NOT_THE_OWNER");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "YouSwap: NEW_OWNER_IS_THE_ZERO_ADDRESS");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract IDO is Ownable {
    using SafeMath for uint256;

    //Private offering
    mapping(address => uint256) private _ordersOfPriIDO;
    uint256 public startHeightOfPriIDO;
    uint256 public endHeightOfPriIDO;
    uint256 public totalUsdtAmountOfPriIDO = 0;
    uint256 public supplyYouForPriIDO = 5 * 10 ** 11;//50万
    uint256 public reservedYouOfPriIDO = 0;
    uint256 public constant upperLimitUsdtOfPriIDO = 500 * 10 ** 6;//500USDT
    bool public priOfferingFinished = false;
    bool private _priIDOWithdrawFinished = false;

    event PrivateOffering(address indexed participant, uint256 amountOfYou, uint256 amountOfUsdt);
    event PrivateOfferingClaimed(address indexed participant, uint256 amountOfYou);

    //Public offering
    mapping(address => uint256) private _ordersOfPubIDO;
    uint256 public targetUsdtAmountOfPubIDO = 5 * 10 ** 10;//5万USDT
    uint256 public targetYouAmountOfPubIDO = 5 * 10 ** 11;//50万YOU
    uint256 public totalUsdtAmountOfPubIDO = 0;
    uint256 public startHeightOfPubIDO;
    uint256 public endHeightOfPubIDO;
    uint256 public constant bottomLimitUsdtOfPubIDO = 100 * 10 ** 6; //100USDT
    bool private _pubIDOWithdrawFinished = false;

    event PublicOffering(address indexed participant, uint256 amountOfUsdt);
    event PublicOfferingClaimed(address indexed participant, uint256 amountOfYou);
    event PublicOfferingRefund(address indexed participant, uint256 amountOfUsdt);

    mapping(address => uint8) private _whiteList;

    address private constant _usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private _youToken;

    address private constant _vault = 0x6B5C21a770dA1621BB28C9a2b6F282E5FC9154d5;

    constructor(address youToken) public {
        _youToken = youToken;

        startHeightOfPriIDO = 12043919;
        endHeightOfPriIDO = 12045359;

        startHeightOfPubIDO = 12061199;
        endHeightOfPubIDO = 12062639;
    }

    function init(uint256 startHOfPriIDO, uint256 endHOfPriIDO, uint256 startHOfPubIDO, uint256 endHOfPubIDO) onlyOwner public {
        require(block.number + 60 < startHeightOfPriIDO || block.number + 60 < startHeightOfPubIDO, 'YouSwap:TOO_LATE');

        if (block.number + 60 < startHeightOfPriIDO) {
            startHeightOfPriIDO = startHOfPriIDO;
            endHeightOfPriIDO = endHOfPriIDO;

            require(startHeightOfPriIDO + 30 < endHeightOfPriIDO, 'YouSwap:INVALID_PARAMETERS_FOR_PRI_IDO');
        }

        if (block.number + 60 < startHeightOfPubIDO) {
            startHeightOfPubIDO = startHOfPubIDO;
            endHeightOfPubIDO = endHOfPubIDO;

            require(startHeightOfPubIDO + 30 < endHeightOfPubIDO, 'YouSwap:INVALID_PARAMETERS_FOR_PUB_IDO');
        }
    }

    modifier inWhiteList() {
        require(_whiteList[msg.sender] == 1, "YouSwap: NOT_IN_WHITE_LIST");
        _;
    }

    function isInWhiteList(address addr) external view returns (bool) {
        return _whiteList[addr] == 1;
    }

    function addToWhiteList(address addr) external onlyOwner {
        _whiteList[addr] = 1;
    }

    function removeFromWhiteList(address addr) external onlyOwner {
        _whiteList[addr] = 0;
    }

    function claim() inWhiteList external {
        require((block.number >= endHeightOfPriIDO && _ordersOfPriIDO[msg.sender] > 0)
            || (block.number >= endHeightOfPubIDO && _ordersOfPubIDO[msg.sender] > 0), 'YouSwap: FORBIDDEN');

        uint256 reservedYouFromPriIDO = _ordersOfPriIDO[msg.sender];
        if (block.number >= endHeightOfPriIDO && reservedYouFromPriIDO > 0) {
            _mintYou(_youToken, reservedYouFromPriIDO);
            emit PrivateOfferingClaimed(msg.sender, reservedYouFromPriIDO);
            _ordersOfPriIDO[msg.sender] = 0;
        }

        uint256 amountOfUsdtPayed = _ordersOfPubIDO[msg.sender];
        if (block.number >= endHeightOfPubIDO && amountOfUsdtPayed > 0) {
            uint256 reservedYouFromPubIDO = 0;
            if (totalUsdtAmountOfPubIDO > targetUsdtAmountOfPubIDO) {
                uint256 availableAmountOfUsdt = amountOfUsdtPayed.div(totalUsdtAmountOfPubIDO).mul(targetUsdtAmountOfPubIDO);
                reservedYouFromPubIDO = availableAmountOfUsdt.mul(targetYouAmountOfPubIDO.div(targetUsdtAmountOfPubIDO));
                uint256 usdtAmountToRefund = amountOfUsdtPayed.sub(availableAmountOfUsdt);

                if (usdtAmountToRefund > 0) {
                    _transfer(_usdtToken, msg.sender, usdtAmountToRefund);
                    emit PublicOfferingRefund(msg.sender,usdtAmountToRefund);
                }
            }
            else {
                reservedYouFromPubIDO = amountOfUsdtPayed.mul(targetYouAmountOfPubIDO.div(targetUsdtAmountOfPubIDO));
            }

            _mintYou(_youToken, reservedYouFromPubIDO);
            emit PublicOfferingClaimed(msg.sender, reservedYouFromPubIDO);
            _ordersOfPubIDO[msg.sender] = 0;
        }
    }

    function withdrawPriIDO() onlyOwner external {
        require(block.number > endHeightOfPriIDO, 'YouSwap: BLOCK_HEIGHT_NOT_REACHED');
        require(!_priIDOWithdrawFinished, 'YouSwap: PRI_IDO_WITHDRAWN_ALREADY');

        _transfer(_usdtToken, _vault, totalUsdtAmountOfPriIDO);
        _priIDOWithdrawFinished = true;
    }

    function withdrawPubIDO() onlyOwner external {
        require(block.number > endHeightOfPubIDO, 'YouSwap: BLOCK_HEIGHT_NOT_REACHED');
        require(!_pubIDOWithdrawFinished, 'YouSwap: PUB_IDO_WITHDRAWN_ALREADY');

        uint256 amountToWithdraw = totalUsdtAmountOfPubIDO;
        if (totalUsdtAmountOfPubIDO > targetUsdtAmountOfPubIDO) {
            amountToWithdraw = targetUsdtAmountOfPubIDO;
        }

        _transfer(_usdtToken, _vault, amountToWithdraw);
    }

    function privateOffering(uint256 amountOfUsdt) inWhiteList external returns (bool)  {
        require(block.number >= startHeightOfPriIDO, 'YouSwap:NOT_STARTED_YET');
        require(!priOfferingFinished && block.number <= endHeightOfPriIDO, 'YouSwap:PRIVATE_OFFERING_ALREADY_FINISHED');
        require(_ordersOfPriIDO[msg.sender] == 0, 'YouSwap: ATTENDED_ALREADY');
        require(amountOfUsdt <= upperLimitUsdtOfPriIDO, 'YouSwap: EXCEED_THE_UPPER_LIMIT');

        require(reservedYouOfPriIDO < supplyYouForPriIDO, 'YouSwap:INSUFFICIENT_YOU');
        uint256 amountOfYou = amountOfUsdt.mul(10);
        //0.1USDT/YOU
        if (reservedYouOfPriIDO.add(amountOfYou) > supplyYouForPriIDO) {
            amountOfYou = supplyYouForPriIDO.sub(reservedYouOfPriIDO);
            amountOfUsdt = amountOfYou.div(10);

            priOfferingFinished = true;
        }
        _transferFrom(_usdtToken, amountOfUsdt);

        _ordersOfPriIDO[msg.sender] = amountOfYou;
        reservedYouOfPriIDO += amountOfYou;
        totalUsdtAmountOfPriIDO += amountOfUsdt;
        emit PrivateOffering(msg.sender, amountOfYou, amountOfUsdt);

        return true;
    }

    function pubOfferingFinished() public view returns (bool) {
        return block.number > endHeightOfPubIDO;
    }

    function publicOffering(uint256 amountOfUsdt) external returns (bool)  {
        require(block.number >= startHeightOfPubIDO, 'YouSwap:PUBLIC_OFFERING_NOT_STARTED_YET');
        require(block.number <= endHeightOfPubIDO, 'YouSwap:PUBLIC_OFFERING_ALREADY_FINISHED');
        require(amountOfUsdt >= bottomLimitUsdtOfPubIDO, 'YouSwap: 100USDT_AT_LEAST');

        _transferFrom(_usdtToken, amountOfUsdt);

        _ordersOfPubIDO[msg.sender] = _ordersOfPubIDO[msg.sender].add(amountOfUsdt);
        totalUsdtAmountOfPubIDO = totalUsdtAmountOfPubIDO.add(amountOfUsdt);

        emit PublicOffering(msg.sender, amountOfUsdt);

        _whiteList[msg.sender] = 1;

        return true;
    }

    function _transferFrom(address token, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, msg.sender, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }

    function _mintYou(address token, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('mint(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, msg.sender, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }

    function _transfer(address token, address recipient, uint amount) private {

        bytes4 methodId = bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }
}