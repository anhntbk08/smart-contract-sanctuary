// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "../libs/SafeERC20.sol";
import "./CompoundInterfaces.sol";

contract CompoundProxyUserTemplate {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public op;
    address public treasuryFund;
    address public compReward;
    address public user;
    bytes32 public lendingId;
    bool public claimComp = true;
    bool private inited;
    bool private borrowed;

    event Receive(uint256 amount);
    event Success(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 returnBorrow,
        uint256 timeAt
    );
    event Fail(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 returnBorrow,
        uint256 timeAt
    );
    event RepayBorrow(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 timeAt
    );
    event RepayBorrowErc20(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 timeAt
    );
    event Recycle(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 timeAt
    );

    modifier onlyInited() {
        require(inited, "!inited");
        _;
    }

    modifier onlyOp() {
        require(msg.sender == op, "!op");
        _;
    }

    constructor() public {
        inited = true;
    }

    function init(
        address _op,
        address _treasuryFund,
        bytes32 _lendingId,
        address _user,
        address _compReward
    ) public {
        require(!inited, "inited");

        op = _op;
        treasuryFund = _treasuryFund;
        user = _user;
        lendingId = _lendingId;
        compReward = _compReward;
        inited = true;
    }

    function borrow(
        address _asset,
        address payable _for,
        uint256 _lendingAmount,
        uint256 _interestAmount
    ) public onlyInited onlyOp {
        require(borrowed == false, "!borrowed");
        borrowed = true;

        uint256 borrowState = ICompoundCEther(_asset).borrow(_lendingAmount);

        if (borrowState == 0) {
            emit Success(
                _asset,
                _for,
                _lendingAmount,
                borrowState,
                block.timestamp
            );

            _for.transfer(_lendingAmount.sub(_interestAmount));
            msg.sender.transfer(_interestAmount);
        } else {
            emit Fail(
                _asset,
                _for,
                _lendingAmount,
                borrowState,
                block.timestamp
            );
            uint256 cTokenBal = IERC20(_asset).balanceOf(address(this));

            IERC20(_asset).safeTransfer(treasuryFund, cTokenBal);
        }
    }

    function borrowErc20(
        address _asset,
        address _token,
        address _for,
        uint256 _lendingAmount,
        uint256 _interestAmount
    ) public onlyInited onlyOp {
        require(borrowed == false, "!borrowed");
        borrowed = true;

        autoEnterMarkets(_asset);
        autoClaimComp(_asset);

        uint256 borrowState = ICompoundCErc20(_asset).borrow(_lendingAmount);

        // 0 on success, otherwise an Error code
        if (borrowState == 0) {
            emit Success(
                _asset,
                _for,
                _lendingAmount,
                borrowState,
                block.timestamp
            );

            uint256 bal = IERC20(_token).balanceOf(address(this));
            IERC20(address(_token)).safeTransfer(
                _for,
                bal.sub(_interestAmount)
            );
            IERC20(address(_token)).safeTransfer(msg.sender, _interestAmount);
        } else {
            emit Fail(
                _asset,
                _for,
                _lendingAmount,
                borrowState,
                block.timestamp
            );
            uint256 cTokenBal = IERC20(_asset).balanceOf(address(this));

            IERC20(_asset).safeTransfer(treasuryFund, cTokenBal);
        }
    }

    function repayBorrowBySelf(address _asset, address _underlyToken)
        public
        payable
        onlyInited
        onlyOp
        returns (uint256)
    {
        autoClaimComp(_asset);

        uint256 borrows = borrowBalanceCurrent(_asset);
        uint256 bal;

        if (_underlyToken != address(0)) {
            IERC20(_underlyToken).safeApprove(_asset, 0);
            IERC20(_underlyToken).safeApprove(_asset, borrows);

            ICompoundCErc20(_asset).repayBorrow(borrows);

            /* uint256 bal = IERC20(_underlyToken).balanceOf(address(this));

            IERC20(_underlyToken).safeTransfer(_liquidatePool, bal); */
            bal = IERC20(_underlyToken).balanceOf(address(this));

            if (bal > 0) {
                IERC20(_underlyToken).safeTransfer(op, bal);
            }
        } else {
            ICompoundCEther(_asset).repayBorrow{value: borrows}();

            bal = address(this).balance;

            if (bal > 0) {
                // payable(_liquidatePool).transfer(address(this).balance);
                payable(op).transfer(bal);
            }
        }

        uint256 cTokenBal = IERC20(_asset).balanceOf(address(this));

        if (cTokenBal > 0) {
            IERC20(_asset).safeTransfer(treasuryFund, cTokenBal);
        }

        emit Recycle(_asset, user, cTokenBal, block.timestamp);

        return bal;
    }

    function repayBorrow(address _asset, address payable _for)
        public
        payable
        onlyInited
        onlyOp
        returns (uint256)
    {
        autoClaimComp(_asset);

        uint256 received = msg.value;
        uint256 borrows = borrowBalanceCurrent(_asset);

        if (received > borrows) {
            ICompoundCEther(_asset).repayBorrow{value: borrows}();
            // _for.transfer(received - borrows);
        } else {
            ICompoundCEther(_asset).repayBorrow{value: received}();
        }
        // ICompoundCEther(_asset).repayBorrow{value: received}();

        uint256 bal = address(this).balance;

        if (bal > 0) {
            payable(op).transfer(bal);
        }

        uint256 cTokenBal = IERC20(_asset).balanceOf(address(this));

        if (cTokenBal > 0) {
            IERC20(_asset).safeTransfer(treasuryFund, cTokenBal);
        }

        emit RepayBorrow(_asset, _for, msg.value, block.timestamp);

        return bal;
    }

    function repayBorrowErc20(
        address _asset,
        address _underlyToken,
        address _for,
        uint256 _amount
    ) public onlyInited onlyOp returns (uint256) {
        uint256 received = _amount;
        uint256 borrows = borrowBalanceCurrent(_asset);

        // IERC20(_underlyToken).safeApprove(_asset, 0);
        // IERC20(_underlyToken).safeApprove(_asset, _amount);

        // ICompoundCErc20(_asset).repayBorrow(received);
        IERC20(_underlyToken).safeApprove(_asset, 0);
        IERC20(_underlyToken).safeApprove(_asset, _amount);

        if (received > borrows) {
            ICompoundCErc20(_asset).repayBorrow(borrows);
            // IERC20(_underlyToken).safeTransfer(_for, received - borrows);
        } else {
            ICompoundCErc20(_asset).repayBorrow(received);
        }

        uint256 bal = IERC20(_underlyToken).balanceOf(address(this));

        if (bal > 0) {
            IERC20(_underlyToken).safeTransfer(op, bal);
        }

        uint256 cTokenBal = IERC20(_asset).balanceOf(address(this));

        if (cTokenBal > 0) {
            IERC20(_asset).safeTransfer(treasuryFund, cTokenBal);
        }

        emit RepayBorrow(_asset, _for, _amount, block.timestamp);

        return bal;

        // if (received > borrows) {

        //     ICompoundCErc20(_asset).repayBorrow(borrows);
        //     IERC20(_token).safeTransfer(_for, received - borrows);
        // } else {
        //     ICompoundCErc20(_asset).repayBorrow(received);
        // }

        // emit RepayBorrowErc20(
        //     _asset,
        //     _for,
        //     received - borrows,
        //     block.timestamp
        // );
    }

    function recycle(address _asset, address _underlyToken)
        external
        onlyInited
        onlyOp
    {
        uint256 borrows = borrowBalanceCurrent(_asset);

        if (borrows == 0) {
            if (_underlyToken != address(0)) {
                uint256 surplusBal = IERC20(_underlyToken).balanceOf(
                    address(this)
                );

                if (surplusBal > 0) {
                    IERC20(_underlyToken).safeTransfer(user, surplusBal);
                }
            } else {
                if (address(this).balance > 0) {
                    payable(user).transfer(address(this).balance);
                }
            }

            uint256 cTokenBal = IERC20(_asset).balanceOf(address(this));

            if (cTokenBal > 0) {
                IERC20(_asset).safeTransfer(treasuryFund, cTokenBal);
            }

            emit Recycle(_asset, user, cTokenBal, block.timestamp);
        }
    }

    function autoEnterMarkets(address _asset) internal {
        ICompoundComptroller comptroller = ICompound(_asset).comptroller();

        if (!comptroller.checkMembership(user, _asset)) {
            address[] memory cTokens = new address[](1);

            cTokens[0] = _asset;

            comptroller.enterMarkets(cTokens);
        }
    }

    function autoClaimComp(address _asset) internal {
        if (claimComp) {
            ICompoundComptroller comptroller = ICompound(_asset).comptroller();
            comptroller.claimComp(user);
            address comp = comptroller.getCompAddress();
            uint256 bal = IERC20(comp).balanceOf(address(this));

            IERC20(comp).safeTransfer(compReward, bal);

            ICompoundInterestRewardPool(compReward).queueNewRewards(bal);
        }
    }

    receive() external payable {
        emit Receive(msg.value);
    }

    function borrowBalanceCurrent(address _asset) public returns (uint256) {
        return ICompound(_asset).borrowBalanceCurrent(address(this));
    }

    /* views */
    function borrowBalanceStored(address _asset) public view returns (uint256) {
        return ICompound(_asset).borrowBalanceStored(address(this));
    }

    function getAccountSnapshot(address _asset)
        external
        view
        returns (
            uint256 compoundError,
            uint256 cTokenBalance,
            uint256 borrowBalance,
            uint256 exchangeRateMantissa
        )
    {
        (
            compoundError,
            cTokenBalance,
            borrowBalance,
            exchangeRateMantissa
        ) = ICompound(_asset).getAccountSnapshot(user);
    }

    function getAccountCurrentBalance(address _asset)
        public
        view
        returns (uint256)
    {
        uint256 blocks = block.number.sub(
            ICompound(_asset).accrualBlockNumber()
        );
        uint256 rate = ICompound(_asset).borrowRatePerBlock();
        uint256 borrowBalance = ICompound(_asset).borrowBalanceStored(user);

        return borrowBalance.add(blocks.mul(rate).mul(1e18));
    }

    /* 
        1e18*1e18/297200311178743141766115305/1e8 = 33.64734027477437
        33.64734027477437*1e18*297200311178743141766115305/1e36 = 10000000000
     */
    function getTokenToCToken(address _asset, uint256 _token)
        public
        view
        returns (uint256)
    {
        uint256 exchangeRate = ICompound(_asset).exchangeRateStored();
        uint256 tokens = _token.mul(1e18).mul(exchangeRate).div(
            ICompound(_asset).decimals()
        );

        return tokens;
    }

    function getCTokenToToken(address _asset, uint256 _cToken)
        public
        view
        returns (uint256)
    {
        uint256 exchangeRate = ICompound(_asset).exchangeRateStored();
        uint256 tokens = _cToken
            .mul(ICompound(_asset).decimals())
            .mul(exchangeRate)
            .mul(1e18);

        return tokens;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

interface ICompound {
    function borrow(uint256 borrowAmount) external returns (uint256);
    // function interestRateModel() external returns (InterestRateModel);
    // function comptroller() external view returns (ComptrollerInterface);
    // function balanceOf(address owner) external view returns (uint256);
    function isCToken(address) external view returns(bool);
    function comptroller() external view returns (ICompoundComptroller);
    function redeem(uint redeemTokens) external returns (uint);
    function balanceOf(address owner) external view returns (uint256);
    function getAccountSnapshot(address account) external view returns ( uint256, uint256, uint256, uint256 );
    function accrualBlockNumber() external view returns (uint256);
    function borrowRatePerBlock() external view returns (uint256);
    function borrowBalanceStored(address user) external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function decimals() external view returns (uint256);
    function borrowBalanceCurrent(address account) external returns (uint);
    function interestRateModel() external view returns (address);
}

interface ICompoundCEther is ICompound {
    function repayBorrow() external payable;
    function mint() external payable;
}

interface ICompoundCErc20 is ICompound {
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function mint(uint256 mintAmount) external returns (uint256);
    function underlying() external returns(address); // like usdc usdt
}

interface ICompRewardPool {
    function stakeFor(address _for, uint256 amount) external;
    function withdrawFor(address _for, uint256 amount) external;
    function queueNewRewards(uint256 _rewards) external;
    function rewardToken() external returns(address);
    function rewardConvexToken() external returns(address);

    function getReward(address _account, bool _claimExtras) external returns (bool);
    function earned(address account) external view returns (uint256);
    function balanceOf(address _for) external view returns (uint256);
}

interface ICompRewardFactory {
    function CreateRewards(address _operator) external returns (address);
}

interface ICompoundTreasuryFund {
    function withdrawTo( address _asset, uint256 _amount, address _to ) external;
    // function borrowTo( address _asset, address _underlyAsset, uint256 _borrowAmount, address _to, bool _isErc20 ) external returns (uint256);
    // function repayBorrow( address _asset, bool _isErc20, uint256 _amount ) external payable;
    function claimComp(address _comp,address _comptroller,address _to) external returns(uint256);
}

interface ICompoundTreasuryFundFactory {
    function CreateTreasuryFund(address _operator) external returns (address);
}

interface ICompoundComptroller {
    /*** Assets You Are In ***/
    // 开启抵押
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
    // 关闭抵押
    function exitMarket(address cToken) external returns (uint256);
    function getAssetsIn(address account) external view returns (address[] memory);
    function checkMembership(address account, address cToken) external view returns (bool);

    function claimComp(address holder) external;
    function claimComp(address holder, address[] memory cTokens) external;
    function getCompAddress() external view returns (address);
    function getAllMarkets() external view returns (address[] memory);
    function accountAssets(address user) external view returns (address[] memory);
    function markets(address _cToken) external view returns(bool isListed, uint collateralFactorMantissa);
}

interface ICompoundProxyUserTemplate {
    function init( address _op, address _treasuryFund, bytes32 _lendingId, address _user, address _rewardComp ) external;
    function borrow( address _asset, address payable _for, uint256 _lendingAmount, uint256 _interestAmount ) external;
    function borrowErc20( address _asset, address _token, address _for, uint256 _lendingAmount, uint256 _interestAmount ) external;
    function repayBorrowBySelf(address _asset,address _underlyingToken) external payable returns(uint256);
    function repayBorrow(address _asset, address payable _for) external payable returns(uint256);
    function repayBorrowErc20( address _asset, address _token,address _for, uint256 _amount ) external returns(uint256);
    function op() external view returns (address);
    function asset() external view returns (address);
    function user() external view returns (address);
    function recycle(address _asset,address _underlyingToken) external;
    function borrowBalanceStored(address _asset) external view returns (uint256);
}

interface ICompoundInterestRateModel {
    function blocksPerYear() external view returns (uint256);
}

interface ICompoundPoolFactory {
    // function CreateCompoundRewardPool(address rewardToken,address virtualBalance, address op) external returns (address);
    function CreateRewardPool(address rewardToken, address virtualBalance,address op) external returns (address);
    function CreateTreasuryFundPool(address op) external returns (address);
}

interface ICompoundInterestRewardPool {
    function donate(uint256 _amount) external payable returns (bool);
    function queueNewRewards(uint256 _rewards) external;
    function updateRewardState(address _user) external;
}

interface IRewardPool {
    function earned(address _for) external view returns (uint256);
    function getReward(address _for) external;
    function balanceOf(address _for) external view returns (uint256);
/* function getReward(address _account) external returns (bool);
    function earned(address account) external view returns (uint256);
    function balanceOf(address _for) external view returns (uint256); */
}

interface ILendFlareGague {
    function user_checkpoint(address addr) external returns (bool);
}

interface ILendFlareMinter {
    function mint_for(address gauge_addr, address _for) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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