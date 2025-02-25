/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol

// 

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol

// 

pragma solidity ^0.8.0;

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
        assembly { size := extcodesize(account) }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol

// 

pragma solidity ^0.8.0;



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
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

// 

pragma solidity ^0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

// 

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

// 

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol

// 

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol

// 

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

// 

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}



// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol

// 

pragma solidity ^0.8.0;




/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/TokenInterface.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface TokenInterface{
    function burnFrom(address _from, uint _amount) external;
    function mintTo(address _to, uint _amount) external;
}
// File: contracts/LiquidityMining.sol

// 

// Author: Matt Hooft 
// https://github.com/Civitas-Fundamenta
// [email protected])

pragma solidity ^0.8.0;







contract LiquidityMining is Ownable, AccessControl {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    TokenInterface private fundamenta;
    
    //-------RBAC---------------------------

    bytes32 public constant _ADMIN = keccak256("_ADMIN");
    bytes32 public constant _REMOVAL = keccak256("_REMOVAL");
    bytes32 public constant _MOVE = keccak256("_MOVE");
    bytes32 public constant _RESCUE = keccak256("_RESCUE");
    
    //------------Token Vars-------------------
    
    bool public paused;
    bool public addDisabled;
    bool public removePositionOnly;
    
    uint private lockPeriod0;
    uint private lockPeriod1;
    uint private lockPeriod2;
    
    uint private lockPeriodBPScale;
    
    uint private preYieldDivisor;
    
    /**
     * `periodCalc` uses blocks instead of timestamps
     * as a way to determine days. approx. 6500 blocks a day
     *  are mined on the ethereum network. 
     * `periodCalc` can also be configured if this were ever 
     * needed to be changed.  It also helps to lower it during 
     * testing if you are looking at using any of this code.
     */
     
    uint public periodCalc;
    
    //-------Structs/Mappings/Arrays-------------
    
    /**
     * struct to keep track of Liquidity Providers who have 
     * chosen to stake UniswapV2 Liquidity Pool tokens towards 
     * earning FMTA. 
     */ 
    
    struct LiquidityProviders {
        address Provider;
        uint UnlockHeight;
        uint LockedAmount;
        uint Days;
        uint UserBP;
        uint TotalRewardsPaid;
    }
    
    /**
     * struct to keep track of liquidity pools, total
     * rewards paid and total value locked in said pools.
     */
    
    struct PoolInfo {
        IERC20 ContractAddress;
        uint TotalRewardsPaidByPool;
        uint TotalLPTokensLocked;
        uint PoolBonus;
        uint lockPeriod0BasisPoint;
        uint lockPeriod1BasisPoint;
        uint lockPeriod2BasisPoint;
        uint compYield0;
        uint compYield1;
        uint compYield2;
        uint maxPoolBP;
    }
    
    /**
     * PoolInfo is tracked as an array. The length/index 
     * of the array will be used as the variable `_pid` (Pool ID) 
     * throughout the contract.
     */
    
    PoolInfo[] public poolInfo;
    
    /**
     * mapping to keep track of the struct LiquidityProviders 
     * mapeed to user addresses but also maps it to `uint _pid`
     * this makes tracking the same address across multiple pools 
     * with different positions possible as _pid will also be the 
     * index of PoolInfo[]
     */
    
    mapping (uint => mapping (address => LiquidityProviders)) public provider;

    //-------Events--------------

    event PositionAdded (address _account, uint _amount, uint _blockHeight);
    event PositionRemoved (address _account, uint _amount, uint _blockHeight);
    event PositionForceRemoved (address _account, uint _amount, uint _blockHeight);
    event PositionCompounded (address _account, uint _amountAdded, uint _blockHeight);
    event ETHRescued (address _movedBy, address _movedTo, uint _amount, uint _blockHeight);
    event ERC20Movement (address _movedBy, address _movedTo, uint _amount, uint _blockHeight);
    
    
    /**
     * constructor sets initial values for contract intiialization
     */ 
    
    constructor() {
        periodCalc = 6500;
        lockPeriodBPScale = 10000;
        preYieldDivisor = 2;
        lockPeriod0 = 5;
        lockPeriod1 = 10;
        lockPeriod2 = 15;
        removePositionOnly = false;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); //God Mode. DEFAULT_ADMIN_ROLE Must Require _ADMIN ROLE Still to execute _ADMIN functions.
    }
     
     //------------State modifiers---------------------
     
      modifier unpaused() {
        require(!paused, "LiquidityMining: Contract is Paused");
        _;
    }
    
     modifier addPositionNotDisabled() {
        require(!addDisabled, "LiquidityMining: Adding a Position is currently disabled");
        _;
    }
    
    modifier remPosOnly() {
        require(!removePositionOnly, "LiquidityMining: Only Removing a position is allowed at the moment");
        _;
    }
    
    //----------Modifier Functions----------------------

    function setPaused(bool _paused) external {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        paused = _paused;
    }
    
    function setRemovePosOnly(bool _removeOnly) external {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        removePositionOnly = _removeOnly;
    }
    
      function disableAdd(bool _addDisabled) external {
          require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        addDisabled = _addDisabled;
    }
    
    //------------Token Functions----------------------
    
    /**
     * functions to add and remove liquidity Pool pairs to allow users to
     * stake the pools LP Tokens towards earnign rewards. Can only
     * be called by accounts with the `_ADMIN` role and should only 
     * be added once. The index at which the pool pair is stored 
     * will determine the pools `_pid`. Note if you remove a pool the 
     * index remians but is just left empty making the _pid return
     * zero value if called.
     */
    
    function addLiquidityPoolToken(
        IERC20 _lpTokenAddress, 
        uint _bonus, 
        uint _lpbp0, 
        uint _lpbp1, 
        uint _lpbp2, 
        uint _cy0, 
        uint _cy1, 
        uint _cy2,
        uint _mbp) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        poolInfo.push(PoolInfo({
            ContractAddress: _lpTokenAddress,
            TotalRewardsPaidByPool: 0,
            TotalLPTokensLocked: 0,
            PoolBonus: _bonus,
            lockPeriod0BasisPoint: _lpbp0,
            lockPeriod1BasisPoint: _lpbp1,
            lockPeriod2BasisPoint: _lpbp2,
            compYield0: _cy0,
            compYield1: _cy1,
            compYield2: _cy2,
            maxPoolBP: _mbp
        }));
  
    }

    
    function removeLiquidityPoolToken(uint _pid) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        delete poolInfo[_pid];
        
    }
    
    //------------Information Functions------------------
    
    /**
     * return the length of the pool array
     */
    
     function poolLength() external view returns (uint) {
        return poolInfo.length;
    }
    
    /**
     * function to return the contracts balances of LP Tokens
     * staked from different Uniswap pools.
     */

    function contractBalanceByPoolID(uint _pid) public view returns (uint _balance) {
        PoolInfo memory pool = poolInfo[_pid];
        address ca = address(this);
        return pool.ContractAddress.balanceOf(ca);
    }
    
    /**
     * funtion that returns a callers staked position in a pool 
     * using `_pid` as an argument.
     */
    
    function accountPosition(address _account, uint _pid) public view returns (
        address _accountAddress, 
        uint _unlockHeight, 
        uint _lockedAmount, 
        uint _lockPeriodInDays, 
        uint _userDPY, 
        IERC20 _lpTokenAddress,
        uint _totalRewardsPaidFromPool
    ) {
        LiquidityProviders memory p = provider[_pid][_account];
        PoolInfo memory pool = poolInfo[_pid];
        return (
            p.Provider, 
            p.UnlockHeight, 
            p.LockedAmount, 
            p.Days, 
            p.UserBP, 
            pool.ContractAddress,
            pool.TotalRewardsPaidByPool
        );
    }
    
    /**
     * funtion that returns a true or false regarding whether
     * an account as a position in a pool.  Takes the account address
     * and `_pid` as arguments
     */
    
    function hasPosition(address _userAddress, uint _pid) public view returns (bool _hasPosition) {
        LiquidityProviders memory p = provider[_pid][_userAddress];
        if(p.LockedAmount == 0)
        return false;
        else 
        return true;
    }
    
    /**
     * function to show current lock periods.
     */
    
    function showCurrentLockPeriods() external view returns (
        uint _lockPeriod0, 
        uint _lockPeriod1, 
        uint _lockPeriod2
    ) {
        return (
            lockPeriod0, 
            lockPeriod1, 
            lockPeriod2
        );
    }
    
    //-----------Set Functions----------------------
    
    /**
     * function to set the token that will be minting rewards 
     * for Liquidity Providers.
     */
    
    function setTokenContract(TokenInterface _fmta) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        fundamenta = _fmta;
    }
    
    /**
     * allows accounts with the _ADMIN role to set new lock periods.
     */
    
    function setLockPeriods(uint _newPeriod0, uint _newPeriod1, uint _newPeriod2) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        require(_newPeriod2 > _newPeriod1 && _newPeriod1 > _newPeriod0);
        lockPeriod0 = _newPeriod0;
        lockPeriod1 = _newPeriod1;
        lockPeriod2 = _newPeriod2;
    }
    
    /**
     * allows contract owner to set a new `periodCalc`
     */
    
    function setPeriodCalc(uint _newPeriodCalc) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        periodCalc = _newPeriodCalc;
    }

    /**
     * set of functions to set parameters regarding 
     * lock periods and basis points which are used to  
     * calculate a users daily yield. Can only be called 
     * by contract _ADMIN.
     */
    
    function setLockPeriodBasisPoints (
        uint _newLockPeriod0BasisPoint, 
        uint _newLockPeriod1BasisPoint, 
        uint _newLockPeriod2BasisPoint,
        uint _pid) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        poolInfo[_pid].lockPeriod0BasisPoint = _newLockPeriod0BasisPoint;
        poolInfo[_pid].lockPeriod1BasisPoint = _newLockPeriod1BasisPoint;
        poolInfo[_pid].lockPeriod2BasisPoint = _newLockPeriod2BasisPoint;
    }
    
    function setLockPeriodBPScale(uint _newLockPeriodScale) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        lockPeriodBPScale = _newLockPeriodScale;
    
    }

    function setMaxUserBP(uint _newMaxPoolBP, uint _pid) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        PoolInfo storage pool = poolInfo[_pid];
        pool.maxPoolBP = _newMaxPoolBP;
    }
    
    function setCompoundYield (
        uint _newCompoundYield0, 
        uint _newCompoundYield1, 
        uint _newCompoundYield2,
        uint _pid) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        poolInfo[_pid].compYield0 = _newCompoundYield0;
        poolInfo[_pid].compYield1 = _newCompoundYield1;
        poolInfo[_pid].compYield2 = _newCompoundYield2;
        
    }
    
    function setPoolBonus(uint _pid, uint _bonus) public {
        require(hasRole(_ADMIN, msg.sender));
        poolInfo[_pid].PoolBonus = _bonus;
    }

    function setPreYieldDivisor(uint _newDivisor) public {
        require(hasRole(_ADMIN, msg.sender),"LiquidityMining: Message Sender must be _ADMIN");
        preYieldDivisor = _newDivisor;
    }
    
    //-----------Position/Rewards Functions------------------
    
    /**
     * this function allows a user to add a liquidity Staking
     * position.  The user will need to choose one of the three
     * configured lock Periods. Users may add to the position 
     * only once per lock period.
     */
    
    function addPosition(uint _lpTokenAmount, uint _lockPeriod, uint _pid) public addPositionNotDisabled unpaused{
        LiquidityProviders storage p = provider[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        address ca = address(this);
        require(p.LockedAmount == 0, "LiquidityMining: This account already has a position");
        if(_lockPeriod == lockPeriod0) {
            pool.ContractAddress.safeTransferFrom(msg.sender, ca, _lpTokenAmount);
            uint _preYield = _lpTokenAmount.mul(pool.lockPeriod0BasisPoint.add(pool.PoolBonus)).div(lockPeriodBPScale).mul(_lockPeriod);
            provider[_pid][msg.sender] = LiquidityProviders (
                msg.sender, 
                block.number.add(periodCalc.mul(lockPeriod0)), 
                _lpTokenAmount, 
                lockPeriod0, 
                pool.lockPeriod0BasisPoint,
                p.TotalRewardsPaid.add(_preYield.div(preYieldDivisor))
            );
            fundamenta.mintTo(msg.sender, _preYield.div(preYieldDivisor));
            pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.add(_lpTokenAmount);
            pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(_preYield.div(preYieldDivisor));
        } else if (_lockPeriod == lockPeriod1) {
            pool.ContractAddress.safeTransferFrom(msg.sender, ca, _lpTokenAmount);
            uint _preYield = _lpTokenAmount.mul(pool.lockPeriod1BasisPoint.add(pool.PoolBonus)).div(lockPeriodBPScale).mul(_lockPeriod);
            provider[_pid][msg.sender] = LiquidityProviders (
                msg.sender, 
                block.number.add(periodCalc.mul(lockPeriod1)), 
                _lpTokenAmount, 
                lockPeriod1, 
                pool.lockPeriod1BasisPoint,
                p.TotalRewardsPaid.add(_preYield.div(preYieldDivisor))
            );
            fundamenta.mintTo(msg.sender, _preYield.div(preYieldDivisor));
            pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.add(_lpTokenAmount);
            pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(_preYield.div(preYieldDivisor));
        } else if (_lockPeriod == lockPeriod2) {
            pool.ContractAddress.safeTransferFrom(msg.sender, ca, _lpTokenAmount);
            uint _preYield = _lpTokenAmount.mul(pool.lockPeriod2BasisPoint.add(pool.PoolBonus)).div(lockPeriodBPScale).mul(_lockPeriod);
            provider[_pid][msg.sender] = LiquidityProviders (
                msg.sender, 
                block.number.add(periodCalc.mul(lockPeriod2)), 
                _lpTokenAmount, 
                lockPeriod2, 
                pool.lockPeriod2BasisPoint,
                p.TotalRewardsPaid.add(_preYield.div(preYieldDivisor))
            );
            fundamenta.mintTo(msg.sender, _preYield.div(preYieldDivisor));
            pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.add(_lpTokenAmount);
            pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(_preYield.div(preYieldDivisor));
        }else revert("LiquidityMining: Incompatible Lock Period");
      emit PositionAdded (
          msg.sender,
          _lpTokenAmount,
          block.number
      );
    }
    
    /**
     * allows a user to remove a liquidity staking position
     * and will withdraw any pending rewards. User must withdraw 
     * the entire position.
     */
    
    function removePosition(uint _pid) external unpaused {
        LiquidityProviders storage p = provider[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        //require(_lpTokenAmount == p.LockedAmount, "LiquidyMining: Either you do not have a position or you must remove the entire amount.");
        require(p.UnlockHeight < block.number, "LiquidityMining: Not Long Enough");
            pool.ContractAddress.safeTransfer(msg.sender, p.LockedAmount);
            uint yield = calculateUserDailyYield(_pid);
            fundamenta.mintTo(msg.sender, yield);
            provider[_pid][msg.sender] = LiquidityProviders (
                msg.sender, 
                0, 
                p.LockedAmount.sub(p.LockedAmount),
                0, 
                0,
                p.TotalRewardsPaid.add(yield)
            );
        pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
        pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.sub(p.LockedAmount);
        emit PositionRemoved(
        msg.sender,
        p.LockedAmount,
        block.number
      );
    }

    /**
     * function to forcibly remove a users position.  This 
     * is required due to the fact that the basis points used to 
     * calculate user DPY will be constantly changing.
     * We will need to forceibly remove positions of lazy (or malicious)
     * users who will try to take advantage of DPY being lowered instead 
     * of raised and maintining thier current return levels.
     */
    
    function forcePositionRemoval(uint _pid, address _account) public {
        require(hasRole(_REMOVAL, msg.sender));
        LiquidityProviders storage p = provider[_pid][_account];
        PoolInfo storage pool = poolInfo[_pid];
        uint yield = p.LockedAmount.mul(p.UserBP.add(pool.PoolBonus)).div(lockPeriodBPScale).mul(p.Days);
        fundamenta.mintTo(_account, yield);
        uint _lpTokenAmount = p.LockedAmount;
        pool.ContractAddress.safeTransfer(_account, _lpTokenAmount);
        uint _newLpTokenAmount = p.LockedAmount.sub(_lpTokenAmount);
        provider[_pid][_account] = LiquidityProviders (
            _account, 
            0, 
            _newLpTokenAmount, 
            0, 
            0,
            p.TotalRewardsPaid.add(yield)
        );
        pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
        pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.sub(_lpTokenAmount);
        emit PositionForceRemoved(
        msg.sender,
        _lpTokenAmount,
        block.number
      );
    
    }

    /**
     * calculates a users daily yield. DY is calculated
     * using basis points and the lock period as a multiplier.
     * Basis Points and the scale used are configurble by accounts
     * or contracts that have the _ADMIN Role
     */
    
    function calculateUserDailyYield(uint _pid) public view returns (uint _dailyYield) {
        LiquidityProviders memory p = provider[_pid][msg.sender];
        PoolInfo memory pool = poolInfo[_pid];
        uint dailyYield = p.LockedAmount.mul(p.UserBP.add(pool.PoolBonus)).div(lockPeriodBPScale).mul(p.Days);
        return dailyYield;
    }
    
    /**
     * allow user to withdraw thier accrued yield. Reset 
     * the lock period to continue liquidity mining and apply
     * CDPY to DPY. Allow user to add more stake if desired
     * in the process. Once a user has reached the `maxUserBP`
     * DPY will no longer increase.
     */
    
    function withdrawAccruedYieldAndAdd(uint _pid, uint _lpTokenAmount) public remPosOnly unpaused{
        LiquidityProviders storage p = provider[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        uint yield = calculateUserDailyYield(_pid);
        require(removePositionOnly == false);
        require(p.UnlockHeight < block.number);
        if (_lpTokenAmount != 0) {
            if(p.Days == lockPeriod0) {
                fundamenta.mintTo(msg.sender, yield);
                pool.ContractAddress.safeTransferFrom(msg.sender, address(this), _lpTokenAmount);
                provider[_pid][msg.sender] = LiquidityProviders (
                msg.sender, 
                    block.number.add(periodCalc.mul(lockPeriod0)), 
                    _lpTokenAmount.add(p.LockedAmount), 
                    lockPeriod0, 
                    p.UserBP.add(p.UserBP >= pool.maxPoolBP ? 0 : pool.compYield0),
                    p.TotalRewardsPaid.add(yield)
                );
                pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
                pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.add(_lpTokenAmount);
            } else if (p.Days == lockPeriod1) {
                fundamenta.mintTo(msg.sender, yield);
                pool.ContractAddress.safeTransferFrom(msg.sender, address(this), _lpTokenAmount);
                provider[_pid][msg.sender] = LiquidityProviders (
                    msg.sender, 
                    block.number.add(periodCalc.mul(lockPeriod1)),
                    _lpTokenAmount.add(p.LockedAmount), 
                    lockPeriod1, 
                    p.UserBP.add(p.UserBP >= pool.maxPoolBP ? 0 : pool.compYield1),
                    p.TotalRewardsPaid.add(yield)
                );
                pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
                pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.add(_lpTokenAmount);
            } else if (p.Days == lockPeriod2) {
                fundamenta.mintTo(msg.sender, yield);
                pool.ContractAddress.safeTransferFrom(msg.sender, address(this), _lpTokenAmount);
                provider[_pid][msg.sender] = LiquidityProviders (
                    msg.sender, 
                    block.number.add(periodCalc.mul(lockPeriod2)), 
                    _lpTokenAmount.add(p.LockedAmount), 
                    lockPeriod2, 
                    p.UserBP.add(p.UserBP >= pool.maxPoolBP ? 0 : pool.compYield2),
                    p.TotalRewardsPaid.add(yield)
                );
                pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
                pool.TotalLPTokensLocked = pool.TotalLPTokensLocked.add(_lpTokenAmount);
            } else revert("LiquidityMining: Incompatible Lock Period");
        } else if (_lpTokenAmount == 0) {
            if(p.Days == lockPeriod0) {
                fundamenta.mintTo(msg.sender, yield);
                provider[_pid][msg.sender] = LiquidityProviders (
                    msg.sender, 
                    block.number.add(periodCalc.mul(lockPeriod0)), 
                    p.LockedAmount, 
                    lockPeriod0, 
                    p.UserBP.add(p.UserBP >= pool.maxPoolBP ? 0 : pool.compYield0),
                    p.TotalRewardsPaid.add(yield)
                );
                pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
            } else if (p.Days == lockPeriod1) {
                fundamenta.mintTo(msg.sender, yield);
                provider[_pid][msg.sender] = LiquidityProviders (
                    msg.sender, 
                    block.number.add(periodCalc.mul(lockPeriod1)), 
                    p.LockedAmount, 
                    lockPeriod1, 
                    p.UserBP.add(p.UserBP >= pool.maxPoolBP ? 0 : pool.compYield1),
                    p.TotalRewardsPaid.add(yield)
                );
                pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
            } else if (p.Days == lockPeriod2) {
                fundamenta.mintTo(msg.sender, yield);
                provider[_pid][msg.sender] = LiquidityProviders (
                    msg.sender, 
                    block.number.add(periodCalc.mul(lockPeriod2)), 
                    p.LockedAmount, 
                    lockPeriod2, 
                    p.UserBP.add(p.UserBP >= pool.maxPoolBP ? 0 : pool.compYield2),
                    p.TotalRewardsPaid.add(yield)
                );
                pool.TotalRewardsPaidByPool = pool.TotalRewardsPaidByPool.add(yield);
            }else revert("LiquidityMining: Incompatible Lock Period");
        }else revert("LiquidityMining: ?" );
         emit PositionRemoved (
             msg.sender,
             _lpTokenAmount,
             block.number
         );
    }
    
    //-------Movement Functions---------------------

    
    function moveERC20(address _ERC20, address _dest, uint _ERC20Amount) public {
        require(hasRole(_MOVE, msg.sender));
        IERC20(_ERC20).safeTransfer(_dest, _ERC20Amount);
        emit ERC20Movement (
            msg.sender,
            _dest,
            _ERC20Amount,
            block.number
        );

    }

    function ethRescue(address payable _dest, uint _etherAmount) public {
        require(hasRole(_RESCUE, msg.sender));
        _dest.transfer(_etherAmount);
        emit ETHRescued (
            msg.sender,
            _dest,
            _etherAmount,
            block.number
        );
    }
    
}