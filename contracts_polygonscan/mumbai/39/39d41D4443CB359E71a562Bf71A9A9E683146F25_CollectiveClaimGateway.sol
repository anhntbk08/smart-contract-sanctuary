// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /*
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Base contract for building openzeppelin-upgrades compatible implementations for the {ERC1967Proxy}. It includes
 * publicly available upgrade functions that are called by the plugin and by the secure upgrade mechanism to verify
 * continuation of the upgradability.
 *
 * The {_authorizeUpgrade} function MUST be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC1363Receiver} from "../ERC/IERC1363Receiver.sol";
import {Master} from "../Master/Master.sol";
import {ListingGateway} from "../Gateway/ListingGateway.sol";
import {PlatformData} from "../Data/PlatformData.sol";
import {IDaiPermit} from "../ERC/IDaiPermit.sol";
import {EIP712} from "../EIP/EIP712.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import "hardhat/console.sol";

contract Pool is
    IERC1363Receiver,
    Master,
    Initializable,
    UUPSUpgradeable,
    Pausable
{
    using SafeERC20Upgradeable for ERC20Upgradeable;

    // State Variables
    ListingGateway private lg;
    PlatformData private platformData;
    ERC20Burnable internal infiToken;
    address public devWallet;
    address public daiTokenAddr;
    address public usdtTokenAddr;
    address public usdcTokenAddr;
    bytes32 public DOMAIN_SEPARATOR;

    // Constants
    bytes4 internal constant _INTERFACE_ID_ERC1363_RECEIVER = 0x88a7ca5c;
    bytes32 private constant COIN_TYPE_HASH =
        keccak256(
            "CoinPricingInfo(string coinId,string coinSymbol,uint256 coinPrice,uint256 lastUpdatedAt)"
        );
    bytes32 private constant CREATE_COVER_REQUEST =
        keccak256("CREATE_COVER_REQUEST");
    bytes32 private constant CREATE_COVER_OFFER =
        keccak256("CREATE_COVER_OFFER");

    // Event
    event TokensReceived(
        address indexed operator,
        address indexed from,
        uint256 value,
        bytes data
    );

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAdmin
    {}

    function initialize() public initializer {
        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator("insured-finance", "v2");
    }

    modifier onlyAdmin() {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        _;
    }

    function pause() public onlyAdmin whenNotPaused {
        _pause();
    }

    function unpause() public onlyAdmin whenPaused {
        _unpause();
    }

    function changeDependentContractAddress() external onlyAdmin {
        infiToken = ERC20Burnable(cg.infiTokenAddr());
        lg = ListingGateway(cg.getLatestAddress("LG"));
        devWallet = cg.getLatestAddress("DW");
        daiTokenAddr = cg.getLatestAddress("DT");
        usdtTokenAddr = cg.getLatestAddress("UT");
        usdcTokenAddr = cg.getLatestAddress("UC");
        platformData = PlatformData(cg.getLatestAddress("PD"));
    }

    /**
     * @dev function only able to call by InfiToken Smart Contract when user create Cover Request & Cover Offer
     * read : https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/IERC1363Receiver.sol
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory data
    ) external override whenNotPaused returns (bytes4) {
        require(msg.sender == address(infiToken), "ERR_AUTH_2"); // Only specific token accepted (on this case only INFI)

        // Emit Event
        emit TokensReceived(operator, from, value, data);

        // Decode bytes data
        (bytes32 payType, bytes memory payData) = abi.decode(
            data,
            (bytes32, bytes)
        );

        if (payType == CREATE_COVER_REQUEST) {
            lg.createCoverRequest(from, value, payData);
        } else if (payType == CREATE_COVER_OFFER) {
            lg.createCoverOffer(from, value, payData);
        } else {
            revert("ERC1363Receiver: INVALID_PAY_TYPE");
        }

        return _INTERFACE_ID_ERC1363_RECEIVER;
    }

    /**
     * @dev Burn half of listing fee & transfer half of listing fee to developer wallet
     */
    function transferAndBurnInfi(uint256 listingFee)
        external
        onlyInternal
        whenNotPaused
    {
        // Calculation half of listing fee
        uint256 halfListingFee = listingFee / 2;
        infiToken.burn(halfListingFee); // burn half of listing fee
        if (listingFee % 2 == 1) {
            require(
                infiToken.transfer(devWallet, (halfListingFee + 1)),
                "Infi : transfer failed"
            ); // transfer to dev wallet + 1
        } else {
            require(
                infiToken.transfer(devWallet, halfListingFee),
                "Infi : transfer failed"
            ); // transfer to dev wallet
        }
    }

    /**
     * @dev Calculate listing fee (in infi token)
     * NOTE : This one need to take price from chainlink
     */
    function getListingFee(
        CurrencyType insuredSumCurrency,
        uint256 insuredSum,
        uint256 feeCoinPrice,
        uint80 roundId
    ) external view returns (uint256) {
        uint256 feeCoinPriceDecimal = 6;
        // uint insuredSumInUSD = insuredSum * insuredSumCurrencyPriceOnCL / 10**insuredSumCurrencyDecimalOnCL / 10**insuredSumCurrencyDecimal; // insuredSum in USD
        // uint insuredSumInInfi = insuredSumInUSD * 10**feeCoinPriceDecimal / feeCoinPrice;
        // uint listingFeeInInfi = insuredSumInInfi / 100;  // 1% of insured sum
        // 100_000_000 * 10_000 * 1_000_000 * 10**18 / 100_000 / 100 / 10_000 / 1_000_000

        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(insuredSumCurrency)
        );

        // Get price on chainlink
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            platformData.getOraclePriceFeedAddress(
                cg.getCurrencyName(uint8(insuredSumCurrency))
            )
        );
        (, int256 insuredSumCurrencyPriceOnCL, , , ) = priceFeed.getRoundData(
            roundId
        );

        return
            (insuredSum *
                uint256(insuredSumCurrencyPriceOnCL) *
                10**feeCoinPriceDecimal *
                10**infiToken.decimals()) /
            feeCoinPrice /
            100 /
            10**priceFeed.decimals() /
            10**insuredSumCurrencyDecimal;
    }

    /**
     * @dev Used for transfer token from External Account to this smart contract
     * Called on Create Request, Create Offer, Take Request & Take Offer
     * Only accept DAI, USDT & USDC
     */
    function acceptAsset(
        address from,
        CurrencyType currentyType,
        uint256 amount,
        bytes memory premiumPermit
    ) external onlyInternal whenNotPaused {
        if (currentyType == CurrencyType.DAI) {
            // Approve
            DAIPermit memory permitData = abi.decode(
                premiumPermit,
                (DAIPermit)
            );
            IDaiPermit(daiTokenAddr).permit(
                permitData.holder,
                permitData.spender,
                permitData.nonce,
                permitData.expiry,
                permitData.allowed,
                permitData.sigV,
                permitData.sigR,
                permitData.sigS
            );
            // Transfer from member to smart contract
            require(
                IDaiPermit(daiTokenAddr).transferFrom(
                    from,
                    address(this),
                    amount
                ),
                "DAI : accept asset failed"
            );
        } else if (currentyType == CurrencyType.USDT) {
            ERC20Upgradeable(usdtTokenAddr).safeTransferFrom(
                from,
                address(this),
                amount
            );
        } else if (currentyType == CurrencyType.USDC) {
            // Approve
            EIP2612Permit memory permitData = abi.decode(
                premiumPermit,
                (EIP2612Permit)
            );
            IERC20Permit(usdcTokenAddr).permit(
                permitData.owner,
                permitData.spender,
                permitData.value,
                permitData.deadline,
                permitData.sigV,
                permitData.sigR,
                permitData.sigS
            );
            // Transfer from member to smart contract
            require(
                IERC20(usdcTokenAddr).transferFrom(from, address(this), amount),
                "USDC : accept asset failed"
            );
        }
    }

    /**
     * @dev Used for transfer token from this smart contract to External Account
     * Called on Send Premium to Funder, Claim & Refund
     * Only able to send DAI, USDT & USDC
     */
    function transferAsset(
        address to,
        CurrencyType currentyType,
        uint256 amount
    ) external onlyInternal whenNotPaused {
        if (currentyType == CurrencyType.DAI) {
            require(
                IERC20(daiTokenAddr).transfer(to, amount),
                "DAI : transfer failed"
            );
        } else if (currentyType == CurrencyType.USDT) {
            ERC20Upgradeable(usdtTokenAddr).safeTransfer(to, amount);
        } else if (currentyType == CurrencyType.USDC) {
            require(
                IERC20(usdcTokenAddr).transfer(to, amount),
                "USDC : transfer failed"
            );
        }
    }

    /**
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function verifyMessage(CoinPricingInfo memory coinPricing, address whose)
        external
        view
    {
        require(
            EIP712.recover(
                DOMAIN_SEPARATOR,
                coinPricing.sigV,
                coinPricing.sigR,
                coinPricing.sigS,
                hash(coinPricing)
            ) == whose,
            "ERR_SIGN_NOT_VALID"
        );
    }

    function hash(CoinPricingInfo memory coinPricing)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                COIN_TYPE_HASH,
                keccak256(bytes(coinPricing.coinId)),
                keccak256(bytes(coinPricing.coinSymbol)),
                coinPricing.coinPrice,
                coinPricing.lastUpdatedAt
            );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ClaimData is Master, UUPSUpgradeable {
    // State variable
    Claim[] internal claims;
    mapping(uint256 => uint256[]) internal coverToClaims;
    mapping(uint256 => uint256) public claimToCover;

    CollectiveClaim[] internal collectiveClaims;
    mapping(uint256 => uint256[]) internal requestToCollectiveClaims;
    mapping(uint256 => uint256) public collectiveClaimToRequest;

    // total payout from claim of offer cover,
    // it will record how much payout already done for cover offer
    mapping(uint256 => uint256) public offerIdToPayout;
    mapping(uint256 => uint256) public coverToPayout;
    // Mapping status is valid claim exists on Insurance Cover
    // InsuranceCover.id => true/false
    mapping(uint256 => bool) public isValidClaimExistOnCover;
    // To make sure Cover from Take Offer only used unique roundId to claim
    // Mapping Insurance Cover ||--< Round Id => true/false
    mapping(uint256 => mapping(uint80 => bool)) public coverIdToRoundId;

    // it will record how much payout already done for cover request
    mapping(uint256 => uint256) public requestIdToPayout;
    // Mapping status is valid claim exists on Cover Request
    // CoverRequest.id => true/false
    mapping(uint256 => bool) public isValidClaimExistOnRequest;
    // To make sure Cover from Create Request only used unique roundId to claim
    // Mapping Cover Request ||--< ROund Id => true/false
    mapping(uint256 => mapping(uint80 => bool)) public requestIdToRoundId;

    // total amount of expired payout that owned by platform
    mapping(CurrencyType => uint256) public totalExpiredPayout;

    // Calculate pending claims
    mapping(uint256 => uint16) public offerToPendingClaims;
    mapping(uint256 => uint16) public coverToPendingClaims;
    mapping(uint256 => uint16) public requestToPendingCollectiveClaims;

    // Event
    event ClaimRaise(
        uint256 claimId,
        uint256 coverId,
        uint256 claimTime,
        address holder,
        uint80 roundId,
        uint256 roundTimestamp
    );
    event CollectiveClaimRaise(
        uint256 collectiveClaimId,
        uint256 requestId,
        uint256 claimTime,
        address holder,
        uint256 roundId,
        uint256 roundTimestamp
    );

    modifier onlyAdmin() {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        _;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAdmin
    {}

    /**
     * @dev Create a new Claim
     */
    function addClaim(
        uint256 coverId,
        uint256 offerId,
        uint80 roundId,
        uint256 roundTimestamp,
        address holder
    ) external returns (uint256) {
        // Store Data Claim
        claims.push(Claim(roundId, block.timestamp, 0, ClaimState.MONITORING));
        uint256 claimId = claims.length - 1;
        coverToClaims[coverId].push(claimId);
        claimToCover[claimId] = coverId;
        coverToPendingClaims[coverId]++;
        offerToPendingClaims[offerId]++;

        // Emit event claim
        emit ClaimRaise(
            claimId,
            coverId,
            block.timestamp,
            holder,
            roundId,
            roundTimestamp
        );

        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");

        return claimId;
    }

    /**
     * @dev change payout value over Cover
     */
    function setCoverToPayout(uint256 coverId, uint256 payout) external {
        coverToPayout[coverId] += payout;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev change payout value over Cover Offer
     */
    function setOfferIdToPayout(uint256 offerId, uint256 payout) external {
        offerIdToPayout[offerId] += payout;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get list of claim id(s) over cover
     */
    function getCoverToClaims(uint256 coverId)
        external
        view
        returns (uint256[] memory)
    {
        return coverToClaims[coverId];
    }

    function setCoverIdToRoundId(uint256 coverId, uint80 roundId) external {
        coverIdToRoundId[coverId][roundId] = true;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    function updateClaimState(
        uint256 claimId,
        uint256 offerId,
        ClaimState state
    ) external {
        Claim storage claim = claims[claimId];

        if (
            state != ClaimState.MONITORING &&
            claim.state == ClaimState.MONITORING
        ) {
            coverToPendingClaims[claimToCover[claimId]]--;
            offerToPendingClaims[offerId]--;
        }
        // Update state of Claim
        claim.state = state;

        // Update state of mark Valid  Claim existance
        if (state == ClaimState.VALID) {
            isValidClaimExistOnCover[claimToCover[claimId]] = true;
        }
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get Claim Detail
     */
    function getClaimById(uint256 claimId)
        external
        view
        returns (Claim memory)
    {
        return claims[claimId];
    }

    /**
     * @dev Called when user create claim over Cover Request
     */
    function addCollectiveClaim(
        uint256 requestId,
        uint80 roundId,
        uint256 roundTimestamp,
        address holder
    ) external returns (uint256) {
        collectiveClaims.push(
            CollectiveClaim(roundId, block.timestamp, 0, ClaimState.MONITORING)
        );
        uint256 collectiveClaimId = collectiveClaims.length - 1;
        requestToCollectiveClaims[requestId].push(collectiveClaimId);
        collectiveClaimToRequest[collectiveClaimId] = requestId;
        requestToPendingCollectiveClaims[requestId]++;

        emit CollectiveClaimRaise(
            collectiveClaimId,
            requestId,
            block.timestamp,
            holder,
            roundId,
            roundTimestamp
        );

        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");

        return collectiveClaimId;
    }

    function setRequestIdToRoundId(uint256 requestId, uint80 roundId) external {
        requestIdToRoundId[requestId][roundId] = true;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    function setIsValidClaimExistOnRequest(uint256 requestId) external {
        isValidClaimExistOnRequest[requestId] = true;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Used for update claim status to INVALID, VALID, INVALID_AFTER_EXPIRED & VALID_AFTER_EXPIRED
     */
    function updateCollectiveClaimState(
        uint256 collectiveClaimId,
        ClaimState state
    ) external {
        CollectiveClaim storage collectiveClaim = collectiveClaims[
            collectiveClaimId
        ];

        // Decrease number of pending claims on Cover Request
        if (
            state != ClaimState.MONITORING &&
            collectiveClaim.state == ClaimState.MONITORING
        ) {
            requestToPendingCollectiveClaims[
                collectiveClaimToRequest[collectiveClaimId]
            ]--;
        }

        // Update state
        collectiveClaim.state = state;

        // Give a mark
        if (state == ClaimState.VALID) {
            isValidClaimExistOnRequest[
                collectiveClaimToRequest[collectiveClaimId]
            ] = true;
        }

        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev change payout value over Cover Request
     */
    function setRequestIdToPayout(uint256 requestId, uint256 payout) external {
        requestIdToPayout[requestId] += payout;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get detail of collective claim
     */
    function getCollectiveClaimById(uint256 collectiveClaimId)
        external
        view
        returns (CollectiveClaim memory)
    {
        return collectiveClaims[collectiveClaimId];
    }

    /**
     * @dev Add total payout for valid expired claim
     * @dev totalExpiredPayout variable contain amount of token that own by dev because valid claim is expired
     */
    function addTotalExpiredPayout(CurrencyType currencyType, uint256 amount)
        external
    {
        totalExpiredPayout[currencyType] += amount;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Set total payout to 0, called when developer withdraw token of expired calid claim
     */
    function resetTotalExpiredPayout(CurrencyType currencyType) external {
        totalExpiredPayout[currencyType] = 0;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    function getRequestToCollectiveClaims(uint256 requestId)
        external
        view
        returns (uint256[] memory)
    {
        return requestToCollectiveClaims[requestId];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CoverData is Master, UUPSUpgradeable {
    // State Variables
    InsuranceCover[] internal covers; // InsuranceCover.id
    mapping(address => uint256[]) internal holderToCovers;
    mapping(address => uint256[]) internal funderToCovers;
    mapping(address => uint256[]) internal funderToRequestId;
    mapping(uint256 => uint256[]) internal offerIdToCovers;
    mapping(uint256 => uint256[]) internal requestIdToCovers;
    mapping(uint256 => bool) public isPremiumCollected; //  coverId -> true/false
    mapping(uint256 => uint8) public coverIdToCoverMonths; // Only for Buy Cover / Take Offer
    mapping(uint256 => uint256) public insuranceCoverStartAt; // Only for Buy Cover / Take Offer
    CoverFunding[] internal coverFundings;
    mapping(uint256 => uint256[]) internal requestIdToCoverFundings;
    mapping(address => uint256[]) internal funderToCoverFundings;
    // Funder Address ||--< coverId => true/false
    mapping(address => mapping(uint256 => bool)) public isFunderOfCover;
    // Mapping offer to the most last cover end time
    mapping(uint256 => uint256) public offerIdToLastCoverEndTime;

    // Events
    event Cover(
        uint256 id,
        InsuranceCover cover,
        uint256 startAt,
        uint8 coverMonths,
        address funder
    );
    event Booking(uint256 id, CoverFunding coverFunding);
    event CoverPremiumCollected(uint256 coverId);

    modifier onlyAdmin() {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        _;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAdmin
    {}

    /**
     * @dev Save cover data when user take offer
     */
    function storeCoverByTakeOffer(
        InsuranceCover memory cover,
        uint8 coverMonths,
        address funder
    ) external {
        covers.push(cover);
        uint256 coverId = covers.length - 1;
        offerIdToCovers[cover.offerId].push(coverId);
        holderToCovers[cover.holder].push(coverId);
        funderToCovers[funder].push(coverId);
        coverIdToCoverMonths[coverId] = coverMonths;
        insuranceCoverStartAt[coverId] = block.timestamp;
        isPremiumCollected[coverId] = true;
        isFunderOfCover[funder][coverId] = true;

        // Update the most last cover end time
        uint256 endAt = block.timestamp + (uint256(coverMonths) * 30 days);
        if (endAt > offerIdToLastCoverEndTime[cover.offerId]) {
            offerIdToLastCoverEndTime[cover.offerId] = endAt;
        }

        emit Cover(coverId, cover, block.timestamp, coverMonths, funder);
        emit CoverPremiumCollected(coverId);

        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Save cover data when user take request
     */
    function storeBookingByTakeRequest(CoverFunding memory booking) external {
        coverFundings.push(booking);
        uint256 coverFundingId = coverFundings.length - 1;
        requestIdToCoverFundings[booking.requestId].push(coverFundingId);
        funderToCoverFundings[booking.funder].push(coverFundingId);
        emit Booking(coverFundingId, booking);

        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Save cover data when user take request
     */
    function storeCoverByTakeRequest(
        InsuranceCover memory cover,
        uint8 coverMonths,
        address funder
    ) external {
        covers.push(cover);
        uint256 coverId = covers.length - 1;
        requestIdToCovers[cover.requestId].push(coverId);
        holderToCovers[cover.holder].push(coverId);
        funderToCovers[funder].push(coverId);
        funderToRequestId[funder].push(cover.requestId);
        isFunderOfCover[funder][coverId] = true;
        emit Cover(coverId, cover, 0, coverMonths, funder);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get cover detail
     */
    function getCoverById(uint256 coverId)
        external
        view
        returns (InsuranceCover memory cover)
    {
        cover = covers[coverId];
    }

    /**
     * @dev Get booking detail
     */
    function getBookingById(uint256 bookingId)
        external
        view
        returns (CoverFunding memory coverFunding)
    {
        coverFunding = coverFundings[bookingId];
    }

    /**
     * @dev get cover months for cover that crated from take offer only
     */
    function getCoverMonths(uint256 coverId) external view returns (uint8) {
        return coverIdToCoverMonths[coverId];
    }

    /**
     * @dev get list of cover id over covef offer
     */
    function getCoversByOfferId(uint256 offerId)
        external
        view
        returns (uint256[] memory)
    {
        return offerIdToCovers[offerId];
    }

    /**
     * @dev get list of cover id(s) that funded by member
     */
    function getFunderToCovers(address member)
        external
        view
        returns (uint256[] memory)
    {
        return funderToCovers[member];
    }

    /**
     * @dev called when funder collected premium over success cover
     */
    function setPremiumCollected(uint256 coverId) external {
        isPremiumCollected[coverId] = true;
        emit CoverPremiumCollected(coverId);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev get list of cover id(s) over Cover Request
     */
    function getCoversByRequestId(uint256 requestId)
        external
        view
        returns (uint256[] memory)
    {
        return requestIdToCovers[requestId];
    }

    /**
     * @dev get list of cover request id(s) that funded by member
     */
    function getFunderToRequestId(address funder)
        external
        view
        returns (uint256[] memory)
    {
        return funderToRequestId[funder];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ListingData is Master, UUPSUpgradeable {
    // State Variable
    // Cover Request
    CoverRequest[] internal requests; // CoverRequest.id
    mapping(uint256 => uint256) public requestIdToInsuredSumTaken;
    mapping(address => uint256[]) internal buyerToRequests;
    mapping(string => uint256[]) internal coinIdToRequests;
    mapping(uint256 => uint256) public coverRequestFullyFundedAt;
    mapping(uint256 => bool) public requestIdToRefundPremium;
    mapping(uint256 => bool) public isDepositTakenBack; // coverId -> true/false
    // Cover Offer
    CoverOffer[] internal offers; // CoverOffer.id
    mapping(uint256 => uint256) public offerIdToInsuredSumTaken;
    mapping(address => uint256[]) internal funderToOffers;
    mapping(string => uint256[]) internal coinIdToOffers;
    mapping(uint256 => bool) public isDepositOfOfferTakenBack; // offer id => state of take back deposit

    // Events
    event CreateRequest(
        uint256 id,
        address indexed holder,
        CoverRequest request,
        CoinPricingInfo assetPricing,
        CoinPricingInfo feePricing
    );
    event CreateOffer(
        uint256 id,
        address indexed funder,
        CoverOffer coverOffer,
        CoinPricingInfo feePricing,
        CoinPricingInfo assetPricing,
        uint8 depositPeriod
    );
    event DepositOfOfferTakenBack(uint256 offerId);
    event DepositTakenBack(uint256 coverId);
    event RequestFullyFunded(uint256 requestId, uint256 fullyFundedAt);
    event PremiumRefunded(uint256 requestId);

    modifier onlyAdmin() {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        _;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAdmin
    {}

    /**
     * @dev Save listing data of cover request
     */
    function storedRequest(
        CoverRequest memory inputRequest,
        CoinPricingInfo memory assetPricing,
        CoinPricingInfo memory feePricing,
        address member
    ) external {
        requests.push(inputRequest);
        uint256 requestId = requests.length - 1;
        buyerToRequests[member].push(requestId);
        coinIdToRequests[inputRequest.coinId].push(requestId);
        requestIdToInsuredSumTaken[requestId] = 0; // set insured sum taken to 0 as iniitial value
        emit CreateRequest(
            requestId,
            member,
            inputRequest,
            assetPricing,
            feePricing
        );
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get cover request detail
     */
    function getCoverRequestById(uint256 requestId)
        external
        view
        returns (CoverRequest memory coverRequest)
    {
        return requests[requestId];
    }

    /**
     * @dev Get length of array contains Cover Request(s)
     */
    function getCoverRequestLength() external view returns (uint256) {
        return requests.length;
    }

    /**
     * @dev Save cover offer listing data
     */
    function storedOffer(
        CoverOffer memory inputOffer,
        CoinPricingInfo memory feePricing,
        CoinPricingInfo memory assetPricing,
        uint8 depositPeriod,
        address member
    ) external {
        offers.push(inputOffer);
        uint256 offerId = offers.length - 1;
        funderToOffers[member].push(offerId);
        coinIdToOffers[inputOffer.coinId].push(offerId);
        offerIdToInsuredSumTaken[offerId] = 0; // set insured sum remaining to 0 as initial
        emit CreateOffer(
            offerId,
            member,
            inputOffer,
            feePricing,
            assetPricing,
            depositPeriod
        );
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get detail of Cover Offer
     */
    function getCoverOfferById(uint256 offerId)
        external
        view
        returns (CoverOffer memory coverOffer)
    {
        return offers[offerId];
    }

    /**
     * @dev Get list of offer id(s) that funded by member/funder
     */
    function getCoverOffersListByAddr(address member)
        external
        view
        returns (uint256[] memory)
    {
        return funderToOffers[member];
    }

    /**
     * @dev Get length of array contains Cover Offer(s)
     */
    function getCoverOfferLength() external view returns (uint256) {
        return offers.length;
    }

    /**
     * @dev Called when member take offer to update insured sum taken on Cover Offer
     */
    function updateOfferInsuredSumTaken(
        uint256 offerId,
        uint256 insuredSumTaken
    ) external {
        offerIdToInsuredSumTaken[offerId] = insuredSumTaken;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Called when member take request to update insured sum taken on Cover Request
     */
    function updateRequestInsuredSumTaken(
        uint256 requestId,
        uint256 insuredSumTaken
    ) external {
        requestIdToInsuredSumTaken[requestId] = insuredSumTaken;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Check whether Cover Request reach target
     * @dev For Partial : must reach minimal 25% of insured sum
     * @dev For Full : must react minimal 100% - 2 token of insured sum
     */
    function isRequestReachTarget(uint256 requestId)
        external
        view
        returns (bool)
    {
        CoverRequest memory request = requests[requestId];
        return
            requestIdToInsuredSumTaken[requestId] >= request.insuredSumTarget;
    }

    /**
     * @dev Check whether Cover Request fully funded
     * @dev Must react minimal 100% - 2 token of insured sum
     */
    function isRequestFullyFunded(uint256 requestId)
        external
        view
        returns (bool)
    {
        CoverRequest memory request = requests[requestId];
        uint8 decimal = cg.getCurrencyDecimal(
            uint8(request.insuredSumCurrency)
        );
        uint256 tolerance = 2 * (10**decimal);

        return
            (request.insuredSum - requestIdToInsuredSumTaken[requestId]) <=
            tolerance;
    }

    /**
     * @dev Called when Cover Request fully funded
     */
    function setCoverRequestFullyFundedAt(
        uint256 requestId,
        uint256 fullyFundedAt
    ) external {
        coverRequestFullyFundedAt[requestId] = fullyFundedAt;
        emit RequestFullyFunded(requestId, fullyFundedAt);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Called when holder refund premium
     * @dev Refund premium condition :
     * @dev Withdraw premium of fail Cover Request or Withdraw of remaining premium on Cover Request
     */
    function setRequestIdToRefundPremium(uint256 requestId) external {
        requestIdToRefundPremium[requestId] = true;
        emit PremiumRefunded(requestId);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Called when funder refund/take back deposit
     * @dev Withdraw of remaining deposit on Cover Offer
     */
    function setDepositOfOfferTakenBack(uint256 offerId) external {
        isDepositOfOfferTakenBack[offerId] = true;
        emit DepositOfOfferTakenBack(offerId);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Called when funder refund/take back deposit, to mark deposit had taken
     */
    function setIsDepositTakenBack(uint256 coverId) external {
        isDepositTakenBack[coverId] = true;
        emit DepositTakenBack(coverId);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get list of request id(s) that funded by member
     */
    function getBuyerToRequests(address holder)
        external
        view
        returns (uint256[] memory)
    {
        return buyerToRequests[holder];
    }

    /**
     * @dev Get list of offer id(s) that funded by member/funder
     */
    function getFunderToOffers(address funder)
        external
        view
        returns (uint256[] memory)
    {
        return funderToOffers[funder];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Master} from "../Master/Master.sol";

contract PlatformData is Master {
    // State variables
    Platform[] public platforms;
    Oracle[] public oracles;
    PriceFeed[] public usdPriceFeeds;
    Custodian[] public custodians;
    mapping(string => uint256[]) internal symbolToUsdPriceFeeds;

    // Events
    event NewPlatform(uint256 id, string name, string website);
    event NewOracle(uint256 id, string name, string website);
    event NewCustodian(uint256 id, string name, string website);
    event NewPriceFeed(
        string symbol,
        uint256 usdPriceFeedsId,
        uint256 oracleId,
        uint256 chainId,
        uint8 decimals,
        address proxyAddress
    );

    /**
     * @dev Add New Platform
     */
    function addNewPlatform(string calldata name, string calldata website)
        external
    {
        // Only admin allowed to call
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );

        // Store Data
        platforms.push(Platform(name, website));
        uint256 platformId = platforms.length - 1;
        emit NewPlatform(platformId, name, website);
    }

    /**
     * @dev Add New Oracle
     */
    function addNewOracle(string calldata name, string calldata website)
        external
    {
        // Only admin allowed to call
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );

        // Store Data
        oracles.push(Oracle(name, website));
        uint256 oracleId = oracles.length - 1;
        emit NewOracle(oracleId, name, website);
    }

    /**
     * @dev Add New Custodians
     */
    function addNewCustodian(string calldata name, string calldata website)
        external
    {
        // Only admin allowed to call
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );

        // Store Data
        custodians.push(Custodian(name, website));
        uint256 custodianId = custodians.length - 1;
        emit NewCustodian(custodianId, name, website);
    }

    /**
     * @dev Add New Price Feed
     */
    function addNewPriceFeed(
        string calldata symbol,
        uint256 oracleId,
        uint256 chainId,
        uint8 decimals,
        address proxyAddress
    ) external {
        // Only admin allowed to call
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );

        // Store Data
        usdPriceFeeds.push(
            PriceFeed(oracleId, chainId, decimals, proxyAddress)
        );
        uint256 usdPriceFeedsId = usdPriceFeeds.length - 1;
        symbolToUsdPriceFeeds[symbol].push(usdPriceFeedsId);
        emit NewPriceFeed(
            symbol,
            usdPriceFeedsId,
            oracleId,
            chainId,
            decimals,
            proxyAddress
        );
    }

    /**
     * @dev get price feed address by coin id/symbol
     * @dev coin id reference to coingecko
     */
    function getOraclePriceFeedAddress(string calldata symbol)
        external
        view
        returns (address)
    {
        uint256[] memory priceFeeds = symbolToUsdPriceFeeds[symbol];
        if (priceFeeds.length <= 0) {
            return address(0);
        } else {
            uint256 priceFeedId = priceFeeds[priceFeeds.length - 1];
            PriceFeed memory selectedPriceFeed = usdPriceFeeds[priceFeedId];
            return selectedPriceFeed.proxyAddress;
        }
    }
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016-2019 zOS Global Limited
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.0;

/**
 * @title ECRecover
 * @notice A library that provides a safe ECDSA recovery function
 */
library ECRecover {
    /**
     * @notice Recover signer's address from a signed message
     * @dev Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/65e4ffde586ec89af3b7e9140bdc9235d1254853/contracts/cryptography/ECDSA.sol
     * Modifications: Accept v, r, and s as separate arguments
     * @param digest    Keccak-256 hash digest of the signed message
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     * @return Signer address
     */
    function recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECRecover: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECRecover: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECRecover: invalid signature");

        return signer;
    }
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.0;

import { ECRecover } from "./ECRecover.sol";

/**
 * @title EIP712
 * @notice A library that provides EIP712 helper functions
 */
library EIP712 {
    /**
     * @notice Make EIP712 domain separator
     * @param name      Contract name
     * @param version   Contract version
     * @return Domain separator
     */
    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );
    }

    /**
     * @notice Recover signer's address from a EIP712 signature
     * @param domainSeparator   Domain separator
     * @param v                 v of the signature
     * @param r                 r of the signature
     * @param s                 s of the signature
     * @param typeHashAndData   Type hash concatenated with data
     * @return Signer's address
     */
    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(typeHashAndData)
            )
        );
        return ECRecover.recover(digest, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IDaiPermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IERC1363Receiver Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support transferAndCall or transferFromAndCall
 *  from ERC1363 token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363Receiver {

    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param sender address The address which are token transferred from
     * @param amount uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` unless throwing
     */
    function onTransferReceived(address operator, address sender, uint256 amount, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CoverData} from "../Data/CoverData.sol";
import {ClaimData} from "../Data/ClaimData.sol";
import {ListingData} from "../Data/ListingData.sol";
import {PlatformData} from "../Data/PlatformData.sol";
import {CoverGateway} from "./CoverGateway.sol";
import {ListingGateway} from "./ListingGateway.sol";
import {Master} from "../Master/Master.sol";
import {Pool} from "../Capital/Pool.sol";
import {ClaimHelper} from "./ClaimHelper.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract ClaimGateway is Master, Pausable {
    // State variables
    CoverGateway private coverGateway;
    ListingGateway private listingGateway;
    CoverData private coverData;
    ClaimData private claimData;
    ListingData private listingData;
    PlatformData private platformData;
    Pool private pool;
    ClaimHelper private claimHelper;
    uint256 private constant PHASE_OFFSET = 64;
    uint256 private constant STABLECOINS_STANDARD_PRICE = 1;

    // Events
    event CollectPremium(
        uint256 requestId,
        uint256 coverId,
        address funder,
        uint8 currencyType,
        uint256 totalPremium
    );
    event RefundPremium(
        uint256 requestId,
        address funder,
        uint8 currencyType,
        uint256 totalPremium
    );
    event TakeBackDeposit(
        uint256 offerId,
        address funder,
        uint8 currencyType,
        uint256 totalDeposit
    );
    event RefundDeposit(
        uint256 requestId,
        uint256 coverId,
        address funder,
        uint8 currencyType,
        uint256 totalDeposit
    );
    event ValidClaim(
        uint256 coverId,
        uint256 claimId,
        uint8 payoutCurrency,
        uint256 totalPayout
    );
    event InvalidClaim(uint256 coverId, uint256 claimId);
    // Dev withdraw expired payout
    event WithdrawExpiredPayout(
        address devWallet,
        uint8 currencyType,
        uint256 amount
    );

    modifier onlyAdmin() {
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        _;
    }

    function pause() public onlyAdmin whenNotPaused {
        _pause();
    }

    function unpause() public onlyAdmin whenPaused {
        _unpause();
    }

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );

        coverGateway = CoverGateway(cg.getLatestAddress("CG"));
        listingGateway = ListingGateway(cg.getLatestAddress("LG"));
        coverData = CoverData(cg.getLatestAddress("CD"));
        claimData = ClaimData(cg.getLatestAddress("CM"));
        listingData = ListingData(cg.getLatestAddress("LD"));
        platformData = PlatformData(cg.getLatestAddress("PD"));
        pool = Pool(cg.getLatestAddress("PL"));
        claimHelper = ClaimHelper(cg.getLatestAddress("CH"));
    }

    /**
     * @dev Called when member make claim over cover, that cover come from take offer
     * @param coverId id of cover
     * @param roundId number attribute from subgraph
     */
    function submitClaim(uint256 coverId, uint80 roundId)
        external
        whenNotPaused
    {
        // msg.sender must cover's owner
        InsuranceCover memory cover = coverData.getCoverById(coverId);
        require(cover.holder == msg.sender, "ERR_CLG_1");

        // Only accept coverId that coming from taje offer
        require(cover.listingType == ListingType.OFFER, "ERR_CLG_27");

        // get startAt & endAt of Cover
        uint256 startAt = coverGateway.getStartAt(coverId);
        uint256 endAt = coverGateway.getEndAt(coverId);

        // cover must start
        require(startAt != 0, "ERR_CLG_2");

        // cover must be still active
        require(
            startAt <= block.timestamp && block.timestamp <= endAt,
            "ERR_CLG_3"
        );

        // Make sure there is no valid claim
        // Limit only able to make 1 valid claim &$ cannot make multiple valid claim
        require(!claimData.isValidClaimExistOnCover(coverId), "ERR_CLG_4");

        // Cannot use same roundId to submit claim on cover
        require(!claimData.coverIdToRoundId(coverId, roundId), "ERR_CLG_5");

        // Update Cover to roundId
        claimData.setCoverIdToRoundId(coverId, roundId);

        // Price feed aggregator
        address priceFeedAddr = claimHelper.getPriceFeedAddress(cover);
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        // Call aggregator
        (, , , uint256 eventTimestamp, ) = priceFeed.getRoundData(roundId);

        // validate timestamp of price feed, time of round id must in range of cover period
        require(
            startAt <= eventTimestamp && eventTimestamp <= endAt,
            "ERR_CLG_6"
        );

        // Check 1 hours before roundId, make sure the devaluation id valid
        require(
            claimHelper.isValidPastDevaluation(priceFeedAddr, roundId),
            "ERR_CLG_7"
        );

        // add filing claim
        uint256 claimId = claimData.addClaim(
            coverId,
            cover.offerId,
            roundId,
            eventTimestamp,
            msg.sender
        );

        // + 1 hours is a buffer time
        if (
            (eventTimestamp + cg.monitoringPeriod()) + 1 hours <=
            block.timestamp
        ) {
            // Check validity and make payout
            _checkValidityAndPayout(claimId, priceFeedAddr);
        }
    }

    /**
     * @dev Called by insurance holder for check claim status over cover, that cover come from take offer
     */
    function checkPayout(uint256 claimId) external whenNotPaused {
        uint256 coverId = claimData.claimToCover(claimId);

        // make sure there is no valid claim
        require(!claimData.isValidClaimExistOnCover(coverId), "ERR_CLG_4");

        Claim memory claim = claimData.getClaimById(claimId);
        InsuranceCover memory cover = coverData.getCoverById(coverId);

        // Price feed aggregator
        address priceFeedAddr = claimHelper.getPriceFeedAddress(cover);
        // Call aggregator
        (, , uint256 startedAt, , ) = AggregatorV3Interface(priceFeedAddr)
            .getRoundData(claim.roundId);

        require(
            ((startedAt + cg.monitoringPeriod()) + 1 hours) < block.timestamp,
            "ERR_CLG_8"
        );

        require(
            block.timestamp <=
                (startedAt + cg.monitoringPeriod() + cg.maxPayoutPeriod()),
            "ERR_CLG_9"
        );

        _checkValidityAndPayout(claimId, priceFeedAddr);
    }

    /**
     * @dev Check validity status of pending claim
     */
    function _checkValidityAndPayout(uint256 claimId, address priceFeedAddr)
        internal
        whenNotPaused
    {
        Claim memory claim = claimData.getClaimById(claimId);

        // For stablecoins devaluation will decided based on oracle
        (bool isClaimValid, uint256 assetPrice, uint8 decimals) = claimHelper
            .checkClaimForDevaluation(priceFeedAddr, claim.roundId);

        // Get Cover id
        uint256 coverId = claimData.claimToCover(claimId);
        InsuranceCover memory cover = coverData.getCoverById(coverId);

        if (isClaimValid) {
            // Calculate Payout
            uint256 payout = claimHelper.getPayoutOfCover(
                cover,
                assetPrice,
                decimals
            );

            // Get cover offer
            CoverOffer memory coverOffer = listingData.getCoverOfferById(
                cover.offerId
            );

            // emit event
            emit ValidClaim(
                coverId,
                claimId,
                uint8(coverOffer.insuredSumCurrency),
                payout
            );

            require(
                claimData.coverToPayout(coverId) + payout <= cover.insuredSum,
                "ERR_CLG_10"
            );

            // Set cover to payout
            claimData.setCoverToPayout(coverId, payout);
            // Update total payout of offer cover
            claimData.setOfferIdToPayout(cover.offerId, payout);

            // send payout
            pool.transferAsset(
                cover.holder,
                coverOffer.insuredSumCurrency,
                payout
            );

            // update state of claim
            claimData.updateClaimState(
                claimId,
                cover.offerId,
                ClaimState.VALID
            );
        } else {
            // emit event
            emit InvalidClaim(coverId, claimId);

            // update state of claim
            claimData.updateClaimState(
                claimId,
                cover.offerId,
                ClaimState.INVALID
            );
        }
    }

    /**
     * @dev will only be able to call by funders of cover request to collect premium from holder
     */
    function collectPremiumOfRequestByFunder(uint256 coverId)
        external
        whenNotPaused
    {
        InsuranceCover memory cover = coverData.getCoverById(coverId);
        // Make sure cover coming from provide request
        require(cover.listingType == ListingType.REQUEST, "ERR_CLG_11");
        // check if request is fully funded or (reach target and passing expired date)
        require(
            coverGateway.isRequestCoverSucceed(cover.requestId),
            "ERR_CLG_2"
        );

        // check if msg.sender is funder of cover
        require(coverData.isFunderOfCover(msg.sender, coverId), "ERR_CLG_12");

        // check if funder already collect premium for request
        require(!coverData.isPremiumCollected(coverId), "ERR_CLG_13");

        CoverRequest memory coverRequest = listingData.getCoverRequestById(
            cover.requestId
        );

        // calculate premium for funder
        // formula : (fund provide by funder / insured sum of request) * premium sum
        uint256 totalPremium = (cover.insuredSum * coverRequest.premiumSum) /
            coverRequest.insuredSum;

        // Calcuclate Premium for Provider/Funder (80%) and Dev (20%)
        uint256 premiumToProvider = (totalPremium * 8) / 10;
        uint256 premiumToDev = totalPremium - premiumToProvider;

        // trigger event
        emit CollectPremium(
            cover.requestId,
            coverId,
            msg.sender,
            uint8(coverRequest.premiumCurrency),
            premiumToProvider
        );

        // mark funder as premium collectors
        coverData.setPremiumCollected(coverId);

        // Send 80% to Provider/Funder
        pool.transferAsset(
            msg.sender,
            coverRequest.premiumCurrency,
            premiumToProvider
        );
        // Send 20% to Dev wallet
        pool.transferAsset(
            coverGateway.devWallet(),
            coverRequest.premiumCurrency,
            premiumToDev
        );
    }

    /**
     * @dev only be able to call by holder to refund premium on Cover Request
     */
    function refundPremium(uint256 requestId) external whenNotPaused {
        CoverRequest memory coverRequest = listingData.getCoverRequestById(
            requestId
        );

        // only creator of request
        require(coverRequest.holder == msg.sender, "ERR_CLG_14");

        // check if already refund premium
        require(!listingData.requestIdToRefundPremium(requestId), "ERR_CLG_15");

        // check whethers request if success or fail
        // if request success & fully funded (either FULL FUNDING or PARTIAL FUNDING)
        // only the remaining premiumSum can be withdrawn
        // if request success & partiallly funded & time passing expired listing
        // only the remaining premiumSum can be withdrawn
        // if request unsuccessful & time passing expired listing
        // withdrawn all premium sum
        uint256 premiumWithdrawn;
        if (coverGateway.isRequestCoverSucceed(requestId)) {
            // withdraw remaining premium
            // formula : (remaining insured sum / insured sum of request) * premium sum
            premiumWithdrawn =
                ((coverRequest.insuredSum -
                    listingData.requestIdToInsuredSumTaken(requestId)) *
                    coverRequest.premiumSum) /
                coverRequest.insuredSum;
        } else if (
            !listingData.isRequestReachTarget(requestId) &&
            (block.timestamp > coverRequest.expiredAt)
        ) {
            // fail request, cover request creator will be able to refund all premium
            premiumWithdrawn = coverRequest.premiumSum;
        } else {
            // can be caused by request not fullfil criteria to start cover
            // and not yet reach expired time
            revert("ERR_CLG_16");
        }

        if (premiumWithdrawn != 0) {
            // emit event
            emit RefundPremium(
                requestId,
                msg.sender,
                uint8(coverRequest.premiumCurrency),
                premiumWithdrawn
            );

            // mark the request has been refunded
            listingData.setRequestIdToRefundPremium(requestId);

            // transfer asset
            pool.transferAsset(
                msg.sender,
                coverRequest.premiumCurrency,
                premiumWithdrawn
            );
        } else {
            revert("ERR_CLG_17");
        }
    }

    /**
     * @dev will be call by funder of offer cover will send back deposit that funder already spend for offer cover
     */
    function takeBackDepositOfCoverOffer(uint256 offerId)
        external
        whenNotPaused
    {
        CoverOffer memory coverOffer = listingData.getCoverOfferById(offerId);
        // must call by funder/creator of offer cover
        require(msg.sender == coverOffer.funder, "ERR_CLG_18");

        // current time must passing lockup period
        require(block.timestamp > coverOffer.expiredAt, "ERR_CLG_19");

        // check is there any cover that still depend on this one
        require(
            coverData.offerIdToLastCoverEndTime(offerId) > 0 &&
                block.timestamp > coverData.offerIdToLastCoverEndTime(offerId),
            "ERR_CLG_20"
        );

        // check is pending claim exists
        require(claimData.offerToPendingClaims(offerId) == 0, "ERR_CLG_21");

        // check if already take back deposit
        require(!listingData.isDepositOfOfferTakenBack(offerId), "ERR_CLG_22");

        // check remaining deposit
        uint256 remainingDeposit = coverOffer.insuredSum -
            claimData.offerIdToPayout(offerId);

        if (remainingDeposit > 0) {
            // emit event
            emit TakeBackDeposit(
                offerId,
                msg.sender,
                uint8(coverOffer.insuredSumCurrency),
                remainingDeposit
            );

            // mark deposit already taken
            listingData.setDepositOfOfferTakenBack(offerId);

            // send remaining deposit
            pool.transferAsset(
                msg.sender,
                coverOffer.insuredSumCurrency,
                remainingDeposit
            );
        } else {
            revert("ERR_CLG_24");
        }
    }

    /**
     * @dev will be call by funder that provide a cover request will send back deposit that funder already spend for a cover request
     */
    function refundDepositOfProvideCover(uint256 coverId)
        external
        whenNotPaused
    {
        InsuranceCover memory cover = coverData.getCoverById(coverId);
        // cover must be coming from provide request
        require(cover.listingType == ListingType.REQUEST, "ERR_CLG_24");
        // check if msg.sender is funders of request
        require(coverData.isFunderOfCover(msg.sender, coverId), "ERR_CLG_12");
        // check if already take back deposit
        require(!listingData.isDepositTakenBack(coverId), "ERR_CLG_22");

        // check is there any pending claims on Cover Request
        require(
            claimData.requestToPendingCollectiveClaims(cover.requestId) == 0,
            "ERR_CLG_21"
        );

        CoverRequest memory coverRequest = listingData.getCoverRequestById(
            cover.requestId
        );
        uint256 coverEndAt = coverGateway.getEndAt(coverId);

        // Cover Request is fail when request not reaching target & already passing listing expired time
        bool isCoverRequestFail = !listingData.isRequestReachTarget(
            cover.requestId
        ) && (block.timestamp > coverRequest.expiredAt);

        // Calculate payout for cover & Remaining deposit
        // Payout for the cover = Payout for request * cover.insuredSum / Insured Sum Taken
        uint256 coverToPayout = (claimData.requestIdToPayout(cover.requestId) *
            cover.insuredSum) /
            listingData.requestIdToInsuredSumTaken(cover.requestId);
        // Remaining deposit = Insured Sum - payout for the cover
        uint256 remainingDeposit = cover.insuredSum - coverToPayout;

        // If ( cover request succedd & cover already expired & there is remaining deposit )
        // or cover request fail
        // then able to refund all funding
        // Otherwise cannot do refund
        if (
            (coverGateway.isRequestCoverSucceed(cover.requestId) &&
                coverEndAt < block.timestamp &&
                (remainingDeposit > 0)) || isCoverRequestFail
        ) {
            // emit event
            emit RefundDeposit(
                cover.requestId,
                coverId,
                msg.sender,
                uint8(coverRequest.insuredSumCurrency),
                remainingDeposit
            );

            // mark cover as desposit already taken back
            listingData.setIsDepositTakenBack(coverId);

            // Set Cover Payout
            claimData.setCoverToPayout(coverId, coverToPayout);

            // send deposit
            pool.transferAsset(
                msg.sender,
                coverRequest.insuredSumCurrency,
                remainingDeposit
            );
        } else {
            revert("ERR_CLG_25");
        }
    }

    /**
     * @dev Only be able called by Developer to withdraw Valid Expired Payout
     */
    function withdrawExpiredPayout() external whenNotPaused {
        // Only dev wallet address can call function
        require(msg.sender == cg.getLatestAddress("DW"), "ERR_AUTH_3");

        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            uint256 amount = claimData.totalExpiredPayout(CurrencyType(j));
            if (amount > 0) {
                // Change the value
                claimData.resetTotalExpiredPayout(CurrencyType(j));
                // transfer
                pool.transferAsset(
                    cg.getLatestAddress("DW"),
                    CurrencyType(j),
                    amount
                );
                // Emit event
                emit WithdrawExpiredPayout(
                    cg.getLatestAddress("DW"),
                    uint8(CurrencyType(j)),
                    amount
                );
            }
        }
    }

    /**
     * @dev Check all pending claims over Cover based on Cover listing type and Funder
     */
    function validateAllPendingClaims(ListingType listingType, address funder)
        external
    {
        // get list of listing id
        uint256[] memory listingIds = (listingType == ListingType.OFFER)
            ? listingData.getFunderToOffers(funder)
            : coverData.getFunderToRequestId(funder);

        // Loop and Validate expired pending claims on every listing id
        for (uint256 i = 0; i < listingIds.length; i++) {
            claimHelper.execExpiredPendingClaims(listingType, listingIds[i]);
        }
    }

    /**
     * @dev Check all pending claims over Cover based on Cover listing type and listing id(Cover Request Id/ Cover Offer Id)
     */
    function validatePendingClaims(ListingType listingType, uint256 listingId)
        external
        whenNotPaused
    {
        // Validate expired pending claims
        claimHelper.execExpiredPendingClaims(listingType, listingId);
    }

    /**
     * @dev Check pending claims over Cover
     */
    function validatePendingClaimsByCover(uint256 coverId) external {
        // Get Cover
        InsuranceCover memory cover = coverData.getCoverById(coverId);
        // Price feed aggregator address
        address priceFeedAddr = claimHelper.getPriceFeedAddress(cover);
        // Validate expired pending claims
        claimHelper.execExpiredPendingClaimsByCoverId(priceFeedAddr, coverId);
    }

    /**
     * @dev Check pending claims by claim id
     */
    function validatePendingClaimsById(uint256 claimId) external whenNotPaused {
        // Validate expired pending claims
        claimHelper.checkValidityClaim(claimId);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CoverData} from "../Data/CoverData.sol";
import {ClaimData} from "../Data/ClaimData.sol";
import {ListingData} from "../Data/ListingData.sol";
import {PlatformData} from "../Data/PlatformData.sol";
import {CoverGateway} from "./CoverGateway.sol";
import {ListingGateway} from "./ListingGateway.sol";
import {Master} from "../Master/Master.sol";
import {Pool} from "../Capital/Pool.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ClaimHelper is Master {
    // State variables
    CoverGateway private coverGateway;
    ListingGateway private listingGateway;
    CoverData private coverData;
    ClaimData private claimData;
    ListingData private listingData;
    PlatformData private platformData;
    Pool private pool;
    uint256 private constant PHASE_OFFSET = 64;
    uint256 private constant STABLECOINS_STANDARD_PRICE = 1;

    // Events
    // Indicate there is a fund from expired claim payout that can be owned by platform/dev
    event ExpiredValidClaim(
        uint256 coverId,
        uint256 claimId,
        uint8 payoutCurrency,
        uint256 totalPayout
    );
    // Indicate there the fund from expired claim payout still belongs to funder
    event ExpiredInvalidClaim(uint256 coverId, uint256 claimId);

    event ExpiredValidCollectiveClaim(
        uint256 requestId,
        uint256 collectiveClaimId,
        uint8 payoutCurrency,
        uint256 totalPayout
    );
    event ExpiredInvalidCollectiveClaim(
        uint256 requestId,
        uint256 collectiveClaimId
    );

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );

        coverGateway = CoverGateway(cg.getLatestAddress("CG"));
        listingGateway = ListingGateway(cg.getLatestAddress("LG"));
        coverData = CoverData(cg.getLatestAddress("CD"));
        claimData = ClaimData(cg.getLatestAddress("CM"));
        listingData = ListingData(cg.getLatestAddress("LD"));
        platformData = PlatformData(cg.getLatestAddress("PD"));
        pool = Pool(cg.getLatestAddress("PL"));
    }

    /**
     * @dev Calculate payout amount of Cover (in case member create claim)
     */
    function getPayoutOfCover(
        InsuranceCover memory cover,
        uint256 assetPrice,
        uint8 decimals
    ) public view returns (uint256) {
        require(cover.listingType == ListingType.OFFER, "ERR_CLG_27");

        uint8 insuredSumCurrencyDecimals = cg.getCurrencyDecimal(
            uint8(
                listingData.getCoverOfferById(cover.offerId).insuredSumCurrency
            )
        );

        return
            calculatePayout(
                cover.insuredSum,
                insuredSumCurrencyDecimals,
                assetPrice,
                decimals
            );
    }

    function getPayoutOfRequest(
        uint256 requestId,
        CoverRequest memory coverRequest,
        uint256 assetPrice,
        uint8 decimals
    ) public view returns (uint256) {
        uint8 insuredSumCurrencyDecimals = cg.getCurrencyDecimal(
            uint8(coverRequest.insuredSumCurrency)
        );

        return
            calculatePayout(
                listingData.requestIdToInsuredSumTaken(requestId),
                insuredSumCurrencyDecimals,
                assetPrice,
                decimals
            );
    }

    function calculatePayout(
        uint256 insuredSum,
        uint8 insuredSumCurrencyDecimals,
        uint256 assetPrice,
        uint8 decimals
    ) internal pure returns (uint256) {
        uint256 devaluationPerAsset = (STABLECOINS_STANDARD_PRICE *
            (10**decimals)) - uint256(assetPrice);

        // Get payout in USD : insured sum * asset devaluation
        uint256 payoutInUSD = (insuredSum * devaluationPerAsset) /
            (10**insuredSumCurrencyDecimals);
        // Convert payout in USD to insured sum currency
        uint256 payout = (payoutInUSD * (10**insuredSumCurrencyDecimals)) /
            assetPrice;

        return payout;
    }

    /**
     * @dev Generate Round Id (using chainlinks formula)
     */
    function getRoundId(uint16 phase, uint64 originalId)
        public
        pure
        returns (uint80)
    {
        return uint80((uint256(phase) << PHASE_OFFSET) | originalId);
    }

    /**
     * @dev Split round id to phase id & aggregator round id
     */
    function parseIds(uint256 roundId) public pure returns (uint16, uint64) {
        uint16 phaseId = uint16(roundId >> PHASE_OFFSET);
        uint64 aggregatorRoundId = uint64(roundId);

        return (phaseId, aggregatorRoundId);
    }

    /**
     * @dev Find out median price based on round id (price feed from chainlink)
     * @dev Called when member check claim status\
     * @dev using weighted median formula
     */
    function getMedian(address priceFeedAddr, uint80 startRoundId)
        public
        view
        returns (uint256 medianPrice, uint8 decimals)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);

        // Get Phase Id & start original round id
        (uint16 phaseId, uint64 startOriginalRoundId) = parseIds(startRoundId);

        // Get Latest Round
        (, , uint256 timestampOfLatestRound, , ) = priceFeed.latestRoundData();

        // Get Event Round
        (, , uint256 timestampOfEvent, , ) = priceFeed.getRoundData(
            startRoundId
        );

        require(
            timestampOfEvent + cg.monitoringPeriod() < timestampOfLatestRound,
            "ERR_CLG_8"
        );

        // Initial Value
        uint64 currentOriginalRoundId = startOriginalRoundId;
        uint256[] memory priceArr = new uint256[](72 * 3);
        uint256[] memory timestampArr = new uint256[](72 * 3);
        uint256 startedAtTemp = timestampOfEvent;

        while (startedAtTemp <= timestampOfEvent + cg.monitoringPeriod()) {
            // Get Price
            (, int256 price, , uint256 timestamp, ) = priceFeed.getRoundData(
                getRoundId(phaseId, currentOriginalRoundId)
            );

            require(timestamp > 0, "ERR_CHNLNK_1");

            // update parameter value of loop
            startedAtTemp = timestamp;

            // Save value to array
            priceArr[(currentOriginalRoundId - startOriginalRoundId)] = uint256(
                price
            );
            timestampArr[
                (currentOriginalRoundId - startOriginalRoundId)
            ] = timestamp;

            // increment
            currentOriginalRoundId += 1;
        }

        // Initial Array for time diff
        uint256[] memory timeDiffArr = new uint256[](
            currentOriginalRoundId - startOriginalRoundId - 1
        );

        // Calculation for time different
        for (
            uint256 i = 0;
            i < (currentOriginalRoundId - startOriginalRoundId - 1);
            i++
        ) {
            if (i == 0) {
                timeDiffArr[0] = timestampArr[1] - timestampArr[0];
            } else if (
                i == (currentOriginalRoundId - startOriginalRoundId) - 2
            ) {
                timeDiffArr[i] =
                    (timestampOfEvent + cg.monitoringPeriod()) -
                    timestampArr[i];
            } else {
                timeDiffArr[i] = timestampArr[i + 1] - timestampArr[i];
            }
        }

        // Sorting
        quickSort(
            priceArr,
            timeDiffArr,
            0,
            (int64(currentOriginalRoundId) - int64(startOriginalRoundId) - 2) // last index of array
        );

        // Find Median Price
        uint256 commulativeSum = timestampOfEvent;
        uint256 selectedIndex;
        for (uint256 i = 0; i < timeDiffArr.length; i++) {
            commulativeSum += timeDiffArr[i];
            if (
                commulativeSum >=
                (timestampOfEvent + (cg.monitoringPeriod() / 2))
            ) {
                selectedIndex = i;
                break;
            }
        }

        return (priceArr[selectedIndex], priceFeed.decimals());
    }

    /**
     * @dev Quick Sort Sorting Algorithm, used for sorting price values of chainlink price feeds
     */
    function quickSort(
        uint256[] memory arr,
        uint256[] memory arr2,
        int256 left,
        int256 right
    ) public view {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];

        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                (arr2[uint256(i)], arr2[uint256(j)]) = (
                    arr2[uint256(j)],
                    arr2[uint256(i)]
                );
                i++;
                j--;
            }
        }

        if (left < j) quickSort(arr, arr2, left, j);
        if (i < right) quickSort(arr, arr2, i, right);
    }

    /**
    @dev check validity of devaluation claim
    @return isValidClaim bool as state of valid claim
    @return assetPrice is devaluation price per asset
    @return decimals is decimals of price feed
     */
    function checkClaimForDevaluation(address aggregatorAddress, uint80 roundId)
        public
        view
        returns (
            bool isValidClaim,
            uint256 assetPrice,
            uint8 decimals
        )
    {
        // Get median price and decimals
        (uint256 price, uint8 priceDecimals) = getMedian(
            aggregatorAddress,
            roundId
        );

        // threshold is a price that indicates stablecoins are devalued
        uint256 threshold = ((100 - cg.maxDevaluation()) *
            (STABLECOINS_STANDARD_PRICE * (10**priceDecimals))) / 100;
        // if price under threshold then its mark as devaluation
        // else mark as non-devaluation
        isValidClaim = price < threshold ? true : false;
        return (isValidClaim, price, priceDecimals);
    }

    /**
     * @dev Convert price from stablecoins curency to USD (Currently only support DAI, USDT, USDC)
     */
    function convertPrice(uint256[] memory withdrawable, uint256[] memory lock)
        external
        view
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockInUSD,
            uint8 usdDecimals
        )
    {
        usdDecimals = 6;

        // Loop every currency
        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            uint8 assetDecimals = cg.getCurrencyDecimal(j);
            // Get latest price of stable coins
            string memory coinId = cg.getCurrencyName(j);
            address priceFeedAddr = platformData.getOraclePriceFeedAddress(
                coinId
            );
            AggregatorV3Interface priceFeed = AggregatorV3Interface(
                priceFeedAddr
            );
            (, int256 currentPrice, , , ) = priceFeed.latestRoundData();
            uint8 priceFeedDecimals = priceFeed.decimals();

            // Formula : total asset * price per asset from pricefeed * usd decimals / asset decimals / price feed decimal
            totalWithdrawInUSD += ((withdrawable[j] *
                uint256(currentPrice) *
                (10**usdDecimals)) /
                (10**assetDecimals) /
                (10**priceFeedDecimals));
            totalLockInUSD += ((lock[j] *
                uint256(currentPrice) *
                (10**usdDecimals)) /
                (10**assetDecimals) /
                (10**priceFeedDecimals));
        }

        return (totalWithdrawInUSD, totalLockInUSD, usdDecimals);
    }

    /**
     * @dev validate claim creation by looking at pricing in previous rounds that make up duration of 1 hour (cg.validationPreviousPeriod())
     */
    function isValidPastDevaluation(address priceFeedAddr, uint80 roundId)
        external
        view
        returns (bool isValidDevaluation)
    {
        isValidDevaluation = true;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        // Get Phase Id & start original round id
        (uint16 phaseId, uint64 originalRoundId) = parseIds(roundId);
        // Call aggregator to Get Event Detail
        (, , uint256 eventStartedAt, , ) = priceFeed.getRoundData(roundId);
        uint256 prevStartedAt = 0;

        do {
            // deduct originalRoundId every iteration
            originalRoundId -= 1;

            // Call aggregator to get price and time
            (, int256 price, , uint256 timestamp, ) = priceFeed.getRoundData(
                getRoundId(phaseId, originalRoundId)
            );
            prevStartedAt = timestamp;
            require(uint256(price) > 0 && timestamp > 0, "ERR_PAST_VALUATION");

            // check price, must below standard/below 1$
            // threshold is a price that indicates stablecoins are devalued
            uint256 threshold = ((100 - cg.maxDevaluation()) *
                (STABLECOINS_STANDARD_PRICE * (10**priceFeed.decimals()))) /
                100;

            // Mark as non devaluation is eq or bigger tha nthreshold
            if (uint256(price) >= threshold) {
                isValidDevaluation = false;
                break;
            }

            // Will loop until check last 1 hour price (cg.validationPreviousPeriod())
        } while (
            prevStartedAt > eventStartedAt - cg.validationPreviousPeriod()
        );

        return isValidDevaluation;
    }

    /**
     * @dev Get chainlinks price feed address based on cover
     */
    function getPriceFeedAddress(InsuranceCover memory cover)
        public
        view
        returns (address priceFeedAddr)
    {
        string memory coinId = (cover.listingType == ListingType.REQUEST)
            ? listingData.getCoverRequestById(cover.requestId).coinId
            : listingData.getCoverOfferById(cover.offerId).coinId;
        priceFeedAddr = platformData.getOraclePriceFeedAddress(coinId);
    }

    /**
     * @dev check if any pending claim exists on cover , pending claim is a claim with state "Monitoring" and still on range of payout period
     */
    function isPendingClaimExistOnCover(uint256 coverId)
        external
        view
        returns (bool statePendingClaimExists)
    {
        InsuranceCover memory cover = coverData.getCoverById(coverId);
        address priceFeedAddr = getPriceFeedAddress(cover);

        // Price feed aggregator
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);

        uint256[] memory claimIds = claimData.getCoverToClaims(coverId);

        // Loop all claim on the cover
        for (uint256 j = 0; j < claimIds.length; j++) {
            Claim memory claim = claimData.getClaimById(claimIds[j]);

            // check if any MONITORING claim and still on payout period
            // a.k.a check is there any claims that not yet trigger checkValidityAndPayout function
            if (claim.state == ClaimState.MONITORING) {
                // Call aggregator to get event tomestamp
                (, , , uint256 claimEventTimestamp, ) = priceFeed.getRoundData(
                    claim.roundId
                );

                if (
                    block.timestamp <=
                    (claimEventTimestamp +
                        cg.monitoringPeriod() +
                        cg.maxPayoutPeriod())
                ) {
                    statePendingClaimExists = true;
                    break;
                }
            }
        }
    }

    /**
     * @dev Check status of claim which already expired
     * @dev Expired claim is a claim that exceed the payout period
     */
    function execExpiredPendingClaims(ListingType listingType, uint256 id)
        external
        onlyInternal
    {
        // Price feed aggregator address
        string memory coinId = (listingType == ListingType.REQUEST)
            ? listingData.getCoverRequestById(id).coinId
            : listingData.getCoverOfferById(id).coinId;
        address priceFeedAddr = platformData.getOraclePriceFeedAddress(coinId);

        if (listingType == ListingType.REQUEST) {
            execExpiredPendingClaimsByRequestId(priceFeedAddr, id);
        } else {
            uint256[] memory coverIds = coverData.getCoversByOfferId(id);
            for (uint256 i = 0; i < coverIds.length; i++) {
                execExpiredPendingClaimsByCoverId(priceFeedAddr, coverIds[i]);
            }
        }
    }

    /**
     * @dev Check status of claim which already expired
     * @dev Expired claim is a claim that exceed the payout period
     */
    function execExpiredPendingClaimsByCoverId(
        address priceFeedAddr,
        uint256 coverId
    ) public onlyInternal {
        uint256[] memory claimIds = claimData.getCoverToClaims(coverId);

        for (uint256 j = 0; j < claimIds.length; j++) {
            Claim memory claim = claimData.getClaimById(claimIds[j]);
            if (claim.state == ClaimState.MONITORING) {
                AggregatorV3Interface priceFeed = AggregatorV3Interface(
                    priceFeedAddr
                );
                (, , uint256 startedAt, , ) = priceFeed.getRoundData(
                    claim.roundId
                );
                if (
                    block.timestamp >
                    (startedAt + cg.monitoringPeriod() + cg.maxPayoutPeriod())
                ) {
                    _checkValidityClaim(claimIds[j], priceFeedAddr);
                }
            }
        }
    }

    function execExpiredPendingClaimsByRequestId(
        address priceFeedAddr,
        uint256 requestId
    ) public onlyInternal {
        uint256[] memory collectiveClaimIds = claimData
            .getRequestToCollectiveClaims(requestId);

        for (uint256 j = 0; j < collectiveClaimIds.length; j++) {
            CollectiveClaim memory collectiveClaim = claimData
                .getCollectiveClaimById(collectiveClaimIds[j]);
            if (collectiveClaim.state == ClaimState.MONITORING) {
                AggregatorV3Interface priceFeed = AggregatorV3Interface(
                    priceFeedAddr
                );
                (, , uint256 startedAt, , ) = priceFeed.getRoundData(
                    collectiveClaim.roundId
                );
                if (
                    block.timestamp >
                    (startedAt + cg.monitoringPeriod() + cg.maxPayoutPeriod())
                ) {
                    _checkValidityCollectiveClaim(
                        collectiveClaimIds[j],
                        priceFeedAddr
                    );
                }
            }
        }
    }

    /**
     * @dev Check pending claim by claim id
     */
    function checkValidityClaim(uint256 claimId) external {
        uint256 coverId = claimData.claimToCover(claimId);
        InsuranceCover memory cover = coverData.getCoverById(coverId);

        // Price feed aggregator address
        address priceFeedAddr = getPriceFeedAddress(cover);

        _checkValidityClaim(claimId, priceFeedAddr);
    }

    /**
     * @dev Check pending claim by claim id
     */
    function _checkValidityClaim(uint256 claimId, address priceFeedAddr)
        internal
    {
        Claim memory claim = claimData.getClaimById(claimId);

        // For stablecoins devaluation will decided based on oracle
        (
            bool isClaimValid,
            uint256 assetPrice,
            uint8 decimals
        ) = checkClaimForDevaluation(priceFeedAddr, claim.roundId);

        uint256 coverId = claimData.claimToCover(claimId);
        InsuranceCover memory cover = coverData.getCoverById(coverId);

        if (isClaimValid) {
            // Get cover offer
            CoverOffer memory coverOffer = listingData.getCoverOfferById(
                cover.offerId
            );

            // Calculate Payout
            uint256 payout = 0;
            payout = getPayoutOfCover(cover, assetPrice, decimals);

            emit ExpiredValidClaim(
                coverId,
                claimId,
                uint8(coverOffer.insuredSumCurrency),
                payout
            );

            require(
                claimData.coverToPayout(coverId) + payout <= cover.insuredSum,
                "ERR_CLG_10"
            );

            // Set cover to payout
            claimData.setCoverToPayout(coverId, payout);

            // Update total payout of offer cover
            claimData.setOfferIdToPayout(cover.offerId, payout);

            // update state of claim
            claimData.updateClaimState(
                claimId,
                cover.offerId,
                ClaimState.VALID_AFTER_EXPIRED
            );

            // Update total fund that can be owned by platform
            claimData.addTotalExpiredPayout(
                coverOffer.insuredSumCurrency,
                payout
            );
        } else {
            // Emit events
            emit ExpiredInvalidClaim(coverId, claimId);

            // update state of claim
            claimData.updateClaimState(
                claimId,
                cover.offerId,
                ClaimState.INVALID_AFTER_EXPIRED
            );
        }
    }

    function _checkValidityCollectiveClaim(
        uint256 collectiveClaimId,
        address priceFeedAddr
    ) internal {
        CollectiveClaim memory collectiveClaim = claimData
            .getCollectiveClaimById(collectiveClaimId);

        // For stablecoins devaluation will decided based on oracle
        (
            bool isClaimValid,
            uint256 assetPrice,
            uint8 decimals
        ) = checkClaimForDevaluation(priceFeedAddr, collectiveClaim.roundId);
        // Get Cover id
        uint256 requestId = claimData.collectiveClaimToRequest(
            collectiveClaimId
        );

        if (isClaimValid) {
            CoverRequest memory coverRequest = listingData.getCoverRequestById(
                requestId
            );
            // Calculate Payout
            uint256 payout = getPayoutOfRequest(
                requestId,
                coverRequest,
                assetPrice,
                decimals
            );
            require(
                payout <= listingData.requestIdToInsuredSumTaken(requestId),
                "ERR_CLG_10"
            );
            // emit event
            emit ExpiredValidCollectiveClaim(
                requestId,
                collectiveClaimId,
                uint8(coverRequest.insuredSumCurrency),
                payout
            );
            // Update total payout of offer request
            claimData.setRequestIdToPayout(requestId, payout);

            // update state of claim
            claimData.updateCollectiveClaimState(
                collectiveClaimId,
                ClaimState.VALID_AFTER_EXPIRED
            );
            // Update total fund that can be owned by platform
            claimData.addTotalExpiredPayout(
                coverRequest.insuredSumCurrency,
                payout
            );
        } else {
            // emit event
            emit ExpiredInvalidCollectiveClaim(requestId, collectiveClaimId);
            // update state of claim
            claimData.updateCollectiveClaimState(
                collectiveClaimId,
                ClaimState.INVALID_AFTER_EXPIRED
            );
        }
    }

    function isFunderHasPendingClaims(
        ListingType listingType,
        address funderAddr
    ) external view returns (bool state) {
        uint256[] memory ids = (listingType == ListingType.OFFER)
            ? coverData.getFunderToCovers(funderAddr)
            : coverData.getFunderToRequestId(funderAddr);

        for (uint16 i = 0; i < ids.length; i++) {
            uint16 pendingClaims = (listingType == ListingType.OFFER)
                ? claimData.coverToPendingClaims(ids[i])
                : claimData.requestToPendingCollectiveClaims(ids[i]);

            if (pendingClaims > 0) return true;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {CoverData} from "../Data/CoverData.sol";
import {ClaimData} from "../Data/ClaimData.sol";
import {ListingData} from "../Data/ListingData.sol";
import {PlatformData} from "../Data/PlatformData.sol";
import {CoverGateway} from "./CoverGateway.sol";
import {ListingGateway} from "./ListingGateway.sol";
import {ClaimGateway} from "./ClaimGateway.sol";
import {ClaimHelper} from "./ClaimHelper.sol";
import {Master} from "../Master/Master.sol";
import {Pool} from "../Capital/Pool.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract CollectiveClaimGateway is Master {
    // State variables
    CoverGateway private coverGateway;
    ListingGateway private listingGateway;
    ClaimGateway private claimGateway;
    CoverData private coverData;
    ClaimData private claimData;
    ListingData private listingData;
    PlatformData private platformData;
    ClaimHelper private claimHelper;
    Pool private pool;

    event CollectivePremium(
        address funder,
        uint8 currencyType,
        uint256 totalPremium
    );
    event CollectiveRefundPremium(
        address funder,
        uint8 currencyType,
        uint256 totalPremium
    );
    event CollectiveTakeBackDeposit(
        address funder,
        uint8 currencyType,
        uint256 totalDeposit
    );
    event CollectiveRefundDeposit(
        address funder,
        uint8 currencyType,
        uint256 totalDeposit
    );
    event ValidCollectiveClaim(
        uint256 requestId,
        uint256 collectiveClaimId,
        uint8 payoutCurrency,
        uint256 totalPayout
    );

    event InvalidCollectiveClaim(uint256 requestId, uint256 collectiveClaimId);

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        coverGateway = CoverGateway(cg.getLatestAddress("CG"));
        listingGateway = ListingGateway(cg.getLatestAddress("LG"));
        claimGateway = ClaimGateway(cg.getLatestAddress("CL"));
        coverData = CoverData(cg.getLatestAddress("CD"));
        claimData = ClaimData(cg.getLatestAddress("CM"));
        listingData = ListingData(cg.getLatestAddress("LD"));
        platformData = PlatformData(cg.getLatestAddress("PD"));
        pool = Pool(cg.getLatestAddress("PL"));
        claimHelper = ClaimHelper(cg.getLatestAddress("CH"));
    }

    /**
     * @dev called by creater of request to make a claim
     */
    function collectiveSubmitClaim(uint256 requestId, uint80 roundId) external {
        // Make sure request is succedd request
        require(coverGateway.isRequestCoverSucceed(requestId), "ERR_CLG_25");

        CoverRequest memory coverRequest = listingData.getCoverRequestById(
            requestId
        );
        // cover must be still active
        uint256 startAt = listingData.isRequestFullyFunded(requestId)
            ? listingData.coverRequestFullyFundedAt(requestId)
            : coverRequest.expiredAt;
        require(
            startAt <= block.timestamp &&
                block.timestamp <=
                (startAt + (uint256(coverRequest.coverMonths) * 30 days)), // end at of request
            "ERR_CLG_3"
        );

        // Check request own by msg.sender
        require(coverRequest.holder == msg.sender, "ERR_CLG_14");

        // make sure there is no valid claim
        require(!claimData.isValidClaimExistOnRequest(requestId), "ERR_CLG_4");

        // Cannot use same roundId to submit claim on cover
        require(!claimData.requestIdToRoundId(requestId, roundId), "ERR_CLG_5");
        claimData.setRequestIdToRoundId(requestId, roundId);

        address priceFeedAddr = platformData.getOraclePriceFeedAddress(
            listingData.getCoverRequestById(requestId).coinId
        );

        // Call aggregator
        (, , , uint256 eventTimestamp, ) = AggregatorV3Interface(priceFeedAddr)
            .getRoundData(roundId);

        // validate timestamp of price feed, time of round id must in range of cover period
        require(
            startAt <= eventTimestamp &&
                eventTimestamp <=
                (startAt + (uint256(coverRequest.coverMonths) * 30 days)),
            "ERR_CLG_6"
        );

        // Check 1 hours before roundId, make sure the devaluation id valid
        require(
            claimHelper.isValidPastDevaluation(priceFeedAddr, roundId),
            "ERR_CLG_7"
        );

        uint256 collectiveClaimId = claimData.addCollectiveClaim(
            requestId,
            roundId,
            eventTimestamp,
            msg.sender
        );

        // + 1 hours is a buffer time
        if (
            (eventTimestamp + cg.monitoringPeriod()) + 1 hours <=
            block.timestamp
        ) {
            _checkValidityAndPayout(collectiveClaimId, priceFeedAddr);
        }
    }

    /**
     * @dev Check validity status of pending claim
     */
    function _checkValidityAndPayout(
        uint256 collectiveClaimId,
        address priceFeedAddr
    ) internal {
        CollectiveClaim memory collectiveClaim = claimData
            .getCollectiveClaimById(collectiveClaimId);

        // For stablecoins devaluation will decided based on oracle
        (bool isClaimValid, uint256 assetPrice, uint8 decimals) = claimHelper
            .checkClaimForDevaluation(priceFeedAddr, collectiveClaim.roundId);
        // Get Cover id
        uint256 requestId = claimData.collectiveClaimToRequest(
            collectiveClaimId
        );

        if (isClaimValid) {
            CoverRequest memory coverRequest = listingData.getCoverRequestById(
                requestId
            );
            // Calculate Payout
            uint256 payout = claimHelper.getPayoutOfRequest(
                requestId,
                coverRequest,
                assetPrice,
                decimals
            );

            require(
                payout <= listingData.requestIdToInsuredSumTaken(requestId),
                "ERR_CLG_10"
            );

            // emit event
            emit ValidCollectiveClaim(
                requestId,
                collectiveClaimId,
                uint8(coverRequest.insuredSumCurrency),
                payout
            );

            // Update total payout of offer request
            claimData.setRequestIdToPayout(requestId, payout);
            // send payout
            pool.transferAsset(
                coverRequest.holder,
                coverRequest.insuredSumCurrency,
                payout
            );
            // update state of claim
            claimData.updateCollectiveClaimState(
                collectiveClaimId,
                ClaimState.VALID
            );
        } else {
            // emit event
            emit InvalidCollectiveClaim(requestId, collectiveClaimId);
            // update state of claim
            claimData.updateCollectiveClaimState(
                collectiveClaimId,
                ClaimState.INVALID
            );
        }
    }

    /**
     * @dev function called by funder that provide on success cover request
     * function will send premium back to funder
     */
    function collectivePremiumForFunder() external {
        // Get list cover id of funder
        uint256[] memory listCoverIds = coverData.getFunderToCovers(msg.sender);

        // initialize variable for store total premium for each currency
        uint256[] memory totalPremium = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        // loop each cover
        for (uint256 i = 0; i < listCoverIds.length; i++) {
            uint256 coverId = listCoverIds[i];
            InsuranceCover memory cover = coverData.getCoverById(coverId);

            // only success request cover & premium which not yet collected will be count
            if (
                cover.listingType == ListingType.REQUEST &&
                coverGateway.isRequestCoverSucceed(cover.requestId) &&
                !coverData.isPremiumCollected(coverId)
            ) {
                // mark cover as premium collecter
                coverData.setPremiumCollected(coverId);

                // increase total premium based on currency type (premium currency)
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);
                totalPremium[uint8(coverRequest.premiumCurrency)] +=
                    (cover.insuredSum * coverRequest.premiumSum) /
                    coverRequest.insuredSum;
            }
        }

        // loop every currency
        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            if (totalPremium[j] > 0) {
                // Calcuclate Premium for Provider/Funder (80%) and Dev (20%)
                uint256 premiumToProvider = (totalPremium[j] * 8) / 10;
                uint256 premiumToDev = totalPremium[j] - premiumToProvider;

                // trigger event
                emit CollectivePremium(
                    msg.sender,
                    uint8(CurrencyType(j)),
                    premiumToProvider
                );

                // Send 80% to Provider/Funder
                pool.transferAsset(
                    msg.sender,
                    CurrencyType(j),
                    premiumToProvider
                );

                // Send 20% to Dev wallet
                pool.transferAsset(
                    coverGateway.devWallet(),
                    CurrencyType(j),
                    premiumToDev
                );
            }
        }
    }

    /**
     * @dev View function to return value of total amount of premium, amount of withdrawable premium for each stablecoins currency
     */
    function getWithdrawablePremiumData(address funderAddr)
        external
        view
        returns (
            uint256 totalWithdrawablePremiumInUSD,
            uint256[] memory withdrawablePremiumList,
            uint8 usdDecimals
        )
    {
        // Get list cover id of funder
        uint256[] memory listCoverIds = coverData.getFunderToCovers(funderAddr);

        // initialize variable for store total premium for each currency
        uint256[] memory totalPremium = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        // loop each cover
        for (uint256 i = 0; i < listCoverIds.length; i++) {
            uint256 coverId = listCoverIds[i];
            InsuranceCover memory cover = coverData.getCoverById(coverId);

            // only success request cover & premium which not yet collected will be count
            if (
                cover.listingType == ListingType.REQUEST &&
                coverGateway.isRequestCoverSucceed(cover.requestId) &&
                !coverData.isPremiumCollected(coverId)
            ) {
                // increase total premium based on currency type (premium currency)
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);
                totalPremium[uint8(coverRequest.premiumCurrency)] +=
                    (cover.insuredSum * coverRequest.premiumSum) /
                    coverRequest.insuredSum;
            }
        }

        (totalWithdrawablePremiumInUSD, , usdDecimals) = claimHelper
            .convertPrice(totalPremium, totalPremium);

        return (totalWithdrawablePremiumInUSD, totalPremium, usdDecimals);
    }

    /**
     * @dev return total of premium and total of withdrawable premium
     * called by holder for refund premium from cover request
     */
    function getPremiumDataOfCoverRequest(address holderAddr)
        external
        view
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockPremiumInUSD,
            uint256[] memory withdrawablePremiumList,
            uint8 usdDecimals
        )
    {
        uint256[] memory withdrawablePremium = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        uint256[] memory lockPremium = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        // get list of request id that created by holder
        uint256[] memory listRequestIds = listingData.getBuyerToRequests(
            holderAddr
        );

        for (uint256 i = 0; i < listRequestIds.length; i++) {
            uint256 requestId = listRequestIds[i];
            CoverRequest memory coverRequest = listingData.getCoverRequestById(
                requestId
            );
            bool isRequestCoverSuccedd = coverGateway.isRequestCoverSucceed(
                requestId
            );
            // fail request is request that not react target and already passing listing expired time
            bool isFailRequest = !listingData.isRequestReachTarget(requestId) &&
                (block.timestamp > coverRequest.expiredAt);

            if (!listingData.requestIdToRefundPremium(requestId)) {
                if (isRequestCoverSuccedd || isFailRequest) {
                    withdrawablePremium[
                        uint8(coverRequest.premiumCurrency)
                    ] += (
                        isFailRequest
                            ? coverRequest.premiumSum
                            : (((coverRequest.insuredSum -
                                listingData.requestIdToInsuredSumTaken(
                                    requestId
                                )) * coverRequest.premiumSum) /
                                coverRequest.insuredSum)
                    );
                } else {
                    lockPremium[
                        uint8(coverRequest.premiumCurrency)
                    ] += coverRequest.premiumSum;
                }
            }
        }

        (totalWithdrawInUSD, totalLockPremiumInUSD, usdDecimals) = claimHelper
            .convertPrice(withdrawablePremium, lockPremium);

        return (
            totalWithdrawInUSD,
            totalLockPremiumInUSD,
            withdrawablePremium,
            usdDecimals
        );
    }

    /**
     * @dev function called by holder of failed cover request
     * @dev function will send premium back to holder
     */
    function collectiveRefundPremium() external {
        // get list of request id that created by holder
        uint256[] memory listRequestIds = listingData.getBuyerToRequests(
            msg.sender
        );
        uint256[] memory premiumWithdrawn = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        for (uint256 i = 0; i < listRequestIds.length; i++) {
            uint256 requestId = listRequestIds[i];
            CoverRequest memory coverRequest = listingData.getCoverRequestById(
                requestId
            );
            bool isRequestCoverSuccedd = coverGateway.isRequestCoverSucceed(
                requestId
            );

            // fail request is request that not react target and already passing listing expired time
            bool isFailRequest = !listingData.isRequestReachTarget(requestId) &&
                (block.timestamp > coverRequest.expiredAt);

            // only request that
            // not yet refunded & (succedd request or fail request)
            // will count
            if (
                coverRequest.holder == msg.sender &&
                !listingData.requestIdToRefundPremium(requestId) &&
                (isRequestCoverSuccedd || isFailRequest)
            ) {
                // if fail request
                // then increase by CoverRequest.premiumSum a.k.a refund all premium
                // if cover succedd
                // then using formula : (remaining insured sum / insured sum of request) * premium sum
                // a.k.a only refund remaining premim sum
                premiumWithdrawn[uint8(coverRequest.premiumCurrency)] += (
                    isFailRequest
                        ? coverRequest.premiumSum
                        : (((coverRequest.insuredSum -
                            listingData.requestIdToInsuredSumTaken(requestId)) *
                            coverRequest.premiumSum) / coverRequest.insuredSum)
                );

                // mark request as refunded
                listingData.setRequestIdToRefundPremium(requestId);
            }
        }

        // loop every currency
        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            if (premiumWithdrawn[j] > 0) {
                // emit event
                emit CollectiveRefundPremium(
                    msg.sender,
                    uint8(CurrencyType(j)),
                    premiumWithdrawn[j]
                );
                // transfer asset
                pool.transferAsset(
                    msg.sender,
                    CurrencyType(j),
                    premiumWithdrawn[j]
                );
            }
        }
    }

    /**
     * @dev return total of locked deposit and total of withdrawable deposit
     * called by funder
     */
    function getDepositDataOfOfferCover(address funderAddr)
        external
        view
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockDepositInUSD,
            uint256[] memory withdrawableDepositList,
            uint8 usdDecimals
        )
    {
        uint256[] memory withdrawableDeposit = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        uint256[] memory lockDeposit = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        // Get List Id of offers
        uint256[] memory listOfferIds = listingData.getFunderToOffers(
            funderAddr
        );

        for (uint256 i = 0; i < listOfferIds.length; i++) {
            // Get Offer Id
            uint256 offerId = listOfferIds[i];
            CoverOffer memory coverOffer = listingData.getCoverOfferById(
                offerId
            );

            if (!listingData.isDepositOfOfferTakenBack(offerId)) {
                if (
                    block.timestamp > coverOffer.expiredAt &&
                    (coverData.offerIdToLastCoverEndTime(offerId) > 0 &&
                        block.timestamp >
                        coverData.offerIdToLastCoverEndTime(offerId)) &&
                    (claimData.offerToPendingClaims(offerId) == 0)
                ) {
                    // Get Withdrawable Deposit a.k.a deposit that not locked
                    // deduct by by payout
                    withdrawableDeposit[uint8(coverOffer.insuredSumCurrency)] +=
                        coverOffer.insuredSum -
                        claimData.offerIdToPayout(offerId);
                } else {
                    // Get Lock Deposit deduct by by payout
                    lockDeposit[uint8(coverOffer.insuredSumCurrency)] +=
                        coverOffer.insuredSum -
                        claimData.offerIdToPayout(offerId);
                }
            }
        }

        (totalWithdrawInUSD, totalLockDepositInUSD, usdDecimals) = claimHelper
            .convertPrice(withdrawableDeposit, lockDeposit);

        return (
            totalWithdrawInUSD,
            totalLockDepositInUSD,
            withdrawableDeposit,
            usdDecimals
        );
    }

    /**
     * @dev function called by funder which creator of cover offer
     * function will send back deposit to funder
     */
    function collectiveRefundDepositOfCoverOffer() external {
        require(
            !claimHelper.isFunderHasPendingClaims(
                ListingType.OFFER,
                msg.sender
            ),
            "ERR_CLG_21"
        );
        // get list offer id of funder
        uint256[] memory listOfferIds = listingData.getFunderToOffers(
            msg.sender
        );
        uint256[] memory remainingDeposit = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        for (uint256 i = 0; i < listOfferIds.length; i++) {
            uint256 offerId = listOfferIds[i];
            CoverOffer memory coverOffer = listingData.getCoverOfferById(
                offerId
            );

            // only cover offer that
            // passing listing expired time
            // & there is no active cover depend on the offer
            // & not yet take back deposit
            if (
                msg.sender == coverOffer.funder &&
                block.timestamp > coverOffer.expiredAt &&
                (coverData.offerIdToLastCoverEndTime(offerId) == 0 ||
                    block.timestamp >
                    coverData.offerIdToLastCoverEndTime(offerId)) &&
                !listingData.isDepositOfOfferTakenBack(offerId) &&
                (claimData.offerToPendingClaims(offerId) == 0)
            ) {
                // increase total deposit based on currency type (premium currency)
                remainingDeposit[uint8(coverOffer.insuredSumCurrency)] +=
                    coverOffer.insuredSum -
                    claimData.offerIdToPayout(offerId);

                // mark deposit already taken
                listingData.setDepositOfOfferTakenBack(offerId);
            }
        }

        // loop every currency
        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            if (remainingDeposit[j] > 0) {
                // emit event
                emit CollectiveTakeBackDeposit(
                    msg.sender,
                    uint8(CurrencyType(j)),
                    remainingDeposit[j]
                );

                // send deposit
                pool.transferAsset(
                    msg.sender,
                    CurrencyType(j),
                    remainingDeposit[j]
                );
            }
        }
    }

    /**
     * @dev return total of locked deposit and total of withdrawable deposit
     * called by funder for refund deposit on provide cover request
     */
    function getDepositOfProvideCover(address funderAddr)
        external
        view
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockDepositInUSD,
            uint256[] memory withdrawableDeposit,
            uint8 usdDecimals
        )
    {
        withdrawableDeposit = new uint256[](uint8(CurrencyType.END_ENUM));
        uint256[] memory lockDeposit = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );
        uint256[] memory listCoverIds = coverData.getFunderToCovers(funderAddr);

        for (uint256 i = 0; i < listCoverIds.length; i++) {
            uint256 coverId = listCoverIds[i];
            InsuranceCover memory cover = coverData.getCoverById(coverId);
            if (
                cover.listingType == ListingType.REQUEST &&
                !listingData.isDepositTakenBack(coverId)
            ) {
                // get Cover Request data
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);
                // get expired time of cover
                uint256 coverEndAt = coverGateway.getEndAt(coverId);
                // Cover Request is fail when request not reaching target & already passing listing expired time
                bool isCoverRequestFail = !listingData.isRequestReachTarget(
                    cover.requestId
                ) && (block.timestamp > coverRequest.expiredAt);
                // Remaining deposit
                uint256 remainingDeposit = cover.insuredSum -
                    claimData.coverToPayout(coverId);

                if (
                    (coverGateway.isRequestCoverSucceed(cover.requestId) &&
                        coverEndAt < block.timestamp &&
                        !claimHelper.isPendingClaimExistOnCover(coverId) &&
                        (remainingDeposit > 0)) || isCoverRequestFail
                ) {
                    // Get withdrawable deposit
                    withdrawableDeposit[
                        uint8(coverRequest.insuredSumCurrency)
                    ] += remainingDeposit;
                } else {
                    // Get Lock Deposit deduct by by payout
                    lockDeposit[
                        uint8(coverRequest.insuredSumCurrency)
                    ] += remainingDeposit;
                }
            }
        }

        (totalWithdrawInUSD, totalLockDepositInUSD, usdDecimals) = claimHelper
            .convertPrice(withdrawableDeposit, lockDeposit);

        return (
            totalWithdrawInUSD,
            totalLockDepositInUSD,
            withdrawableDeposit,
            usdDecimals
        );
    }

    /**
     * @dev function called by FUNDER which PROVIDE FUND for COVER REQUEST
     * function will send back deposit to funder
     */
    function collectiveRefundDepositOfProvideRequest() external {
        require(
            !claimHelper.isFunderHasPendingClaims(
                ListingType.REQUEST,
                msg.sender
            ),
            "ERR_CLG_21"
        );

        // Initialize variabel for calculate deposit
        uint256[] memory deposit = new uint256[](uint8(CurrencyType.END_ENUM));

        // Get list cover id of which funded by funder
        uint256[] memory listCoverIds = coverData.getFunderToCovers(msg.sender);

        for (uint256 i = 0; i < listCoverIds.length; i++) {
            InsuranceCover memory cover = coverData.getCoverById(
                listCoverIds[i]
            );
            if (cover.listingType == ListingType.REQUEST) {
                // get Cover Request data
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);

                // get expired time of cover
                uint256 coverEndAt = coverGateway.getEndAt(listCoverIds[i]);
                // Cover Request is fail when request not reaching target & already passing listing expired time
                bool isCoverRequestFail = !listingData.isRequestReachTarget(
                    cover.requestId
                ) && (block.timestamp > coverRequest.expiredAt);

                // Calculate payout for cover & Remaining deposit
                // Payout for the cover = Payout for request * cover.insuredSum / Insured Sum Taken
                uint256 coverToPayout = (claimData.requestIdToPayout(
                    cover.requestId
                ) * cover.insuredSum) /
                    listingData.requestIdToInsuredSumTaken(cover.requestId);
                // Remaining deposit = Insured Sum - payout for the cover
                uint256 remainingDeposit = cover.insuredSum - coverToPayout;

                // caller must be a funder of the cover
                // deposit not taken back yet
                // there is NO pending claims on the cover
                // ((succedd cover request that passing expired cover time and doesnlt have valid claim) or fail request)
                if (
                    coverData.isFunderOfCover(msg.sender, listCoverIds[i]) &&
                    !listingData.isDepositTakenBack(listCoverIds[i]) &&
                    (claimData.coverToPendingClaims(listCoverIds[i]) == 0) &&
                    ((coverGateway.isRequestCoverSucceed(cover.requestId) &&
                        coverEndAt < block.timestamp &&
                        (remainingDeposit > 0)) || isCoverRequestFail)
                ) {
                    // increase total deposit based on currency type (premium currency)
                    deposit[
                        uint8(coverRequest.insuredSumCurrency)
                    ] += remainingDeposit;

                    // mark cover as desposit already taken back
                    listingData.setIsDepositTakenBack(listCoverIds[i]);

                    // Set Payout for cover
                    claimData.setCoverToPayout(listCoverIds[i], coverToPayout);
                }
            }
        }

        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            if (deposit[j] > 0) {
                // emit event
                emit CollectiveRefundDeposit(
                    msg.sender,
                    uint8(CurrencyType(j)),
                    deposit[j]
                );
                // send deposit
                pool.transferAsset(msg.sender, CurrencyType(j), deposit[j]);
            }
        }
    }

    /**
     * @dev Called by insurance holder for check claim status over cover, that cover come from take request
     */
    function checkPayout(uint256 collectiveClaimId) external {
        uint256 requestId = claimData.collectiveClaimToRequest(
            collectiveClaimId
        );
        // make sure there is no valid claim
        require(!claimData.isValidClaimExistOnRequest(requestId), "ERR_CLG_4");

        CollectiveClaim memory collectiveClaim = claimData
            .getCollectiveClaimById(collectiveClaimId);
        // Price feed aggregator
        address priceFeedAddr = platformData.getOraclePriceFeedAddress(
            listingData.getCoverRequestById(requestId).coinId
        );
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        // Call aggregator
        (, , uint256 startedAt, , ) = priceFeed.getRoundData(
            collectiveClaim.roundId
        );
        require(
            ((startedAt + cg.monitoringPeriod()) + 1 hours) < block.timestamp,
            "ERR_CLG_8"
        );
        // Check status of collective claim , must still on monitoring
        require(collectiveClaim.state == ClaimState.MONITORING, "ERR_CLG_26");
        require(
            block.timestamp <=
                (startedAt + cg.monitoringPeriod() + cg.maxPayoutPeriod()),
            "ERR_CLG_9"
        );

        _checkValidityAndPayout(collectiveClaimId, priceFeedAddr);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Master} from "../Master/Master.sol";
import {CoverData} from "../Data/CoverData.sol";
import {ListingData} from "../Data/ListingData.sol";
import {Pool} from "../Capital/Pool.sol";
import {ListingGateway} from "./ListingGateway.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract CoverGateway is Master, Pausable {
    // State variables
    CoverData private cd;
    ListingData private ld;
    Pool private pool;
    ListingGateway private lg;
    address public coinSigner;
    address public devWallet;
    ERC20Burnable internal infiToken;

    /**
    @dev Check balance of member/sender, minimal have 5000 Infi token. Used in Create Offer, Take Offer and Take Request
    @param _from member/sender's address
    @param _tokenAmount amount of token that used for create listing (will be 0 for take offer and take request)
     */
    modifier minimumBalance(address _from, uint256 _tokenAmount) {
        uint256 tokenAfterTransfer = infiToken.balanceOf(_from);
        uint256 tokenBeforeTransfer = tokenAfterTransfer + _tokenAmount;
        uint256 infiTokenDecimal = 18;
        require(
            tokenBeforeTransfer >= (5000 * (10**infiTokenDecimal)),
            "ERR_AUTH_4"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        _;
    }

    function pause() public onlyAdmin whenNotPaused {
        _pause();
    }

    function unpause() public onlyAdmin whenPaused {
        _unpause();
    }

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        cd = CoverData(cg.getLatestAddress("CD"));
        ld = ListingData(cg.getLatestAddress("LD"));
        lg = ListingGateway(cg.getLatestAddress("LG"));
        pool = Pool(cg.getLatestAddress("PL"));
        coinSigner = cg.getLatestAddress("CS");
        devWallet = cg.getLatestAddress("DW");
        infiToken = ERC20Burnable(cg.infiTokenAddr());
    }

    /**
     * @dev Called when member take an offer
     */
    function buyCover(BuyCover calldata buyCoverData)
        external
        minimumBalance(msg.sender, 0)
        whenNotPaused
    {
        // Get listing data
        CoverOffer memory offer = ld.getCoverOfferById(buyCoverData.offerId);

        // Funder cannot buy own offer
        require(msg.sender != offer.funder, "ERR_CG_1");

        // Check if offer still valid
        require(block.timestamp <= offer.expiredAt, "ERR_CG_2");
        require(buyCoverData.coverMonths >= offer.minCoverMonths, "ERR_CG_3");

        // Check if offer still be able to take (not biggetrthan offer.insuredSumRemaining)
        require(
            buyCoverData.insuredSum <=
                (offer.insuredSum -
                    lg.getInsuredSumTakenOfCoverOffer(buyCoverData.offerId)),
            "ERR_CG_4"
        );

        // verify assetPriceInfo signature
        pool.verifyMessage(buyCoverData.assetPricing, coinSigner);

        //  Validate insured sum
        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(offer.insuredSumCurrency)
        );

        // Check cover qty validity
        require(buyCoverData.coverQty / 10**18 > 0, "ERR_CLG_28");

        // Base Formula : Insured Sum = coverQty * coinPrice
        // coin Price : price of 1 qty to insured sum currency
        // the result will be in insuredSumCurrencyDecumal
        uint256 calculationInsuredSum = (buyCoverData.coverQty * // buyCoverData.coverQty formatted using 18 decimals
            buyCoverData.assetPricing.coinPrice * // buyCoverData.assetPricing.coinPrice formatted using 6 decimals
            (10**insuredSumCurrencyDecimal)) /
            (10**18) / // neutralize cover qty
            (10**6); // neutralize coin price

        require(buyCoverData.insuredSum == calculationInsuredSum, "ERR_CG_5");

        // If full uptake
        if (offer.insuredSumRule == InsuredSumRule.FULL) {
            require(offer.insuredSum == buyCoverData.insuredSum, "ERR_CG_6");
        }

        // Collect Premium, Premium Currenty will follow CoverOffer.premiumCostPerMonth
        uint256 premiumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(offer.premiumCurrency)
        );

        uint256 totalPremium = (buyCoverData.coverQty *
            offer.premiumCostPerMonth *
            buyCoverData.coverMonths) / 10**18; // 10**18 is cover qty decimal

        // Check total premium amount
        require(totalPremium > 0, "ERR_CLG_29");

        // Accept Asset from buyer to pool
        pool.acceptAsset(
            msg.sender,
            offer.premiumCurrency,
            totalPremium,
            buyCoverData.premiumPermit
        );

        // Transfer Premium to Provider (80%) and Dev (20%)
        pool.transferAsset(
            offer.funder,
            offer.premiumCurrency,
            (totalPremium * 8) / 10
        ); // send premium to provider
        pool.transferAsset(
            devWallet,
            offer.premiumCurrency,
            (totalPremium - (totalPremium * 8) / 10)
        ); // send premium to devx

        // Deduct remaining insured sum
        uint256 insuredSumTaken = ld.offerIdToInsuredSumTaken(
            buyCoverData.offerId
        ) + buyCoverData.insuredSum;
        ld.updateOfferInsuredSumTaken(buyCoverData.offerId, insuredSumTaken);

        // Stored Data
        uint8 coverMonths = buyCoverData.coverMonths;
        InsuranceCover memory coverData;
        coverData.offerId = buyCoverData.offerId;
        coverData.requestId = 0;
        coverData.listingType = ListingType.OFFER;
        coverData.holder = buyCoverData.buyer;
        coverData.insuredSum = buyCoverData.insuredSum;
        coverData.coverQty = buyCoverData.coverQty;
        cd.storeCoverByTakeOffer(coverData, coverMonths, offer.funder);
    }

    /**
     * @dev Called when member take a request
     */
    function provideCover(ProvideCover calldata provideCoverData)
        external
        minimumBalance(msg.sender, 0)
        whenNotPaused
    {
        // Get listing data
        CoverRequest memory request = ld.getCoverRequestById(
            provideCoverData.requestId
        );

        // Holder cannot provide own request
        require(msg.sender != request.holder, "ERR_CG_1");

        // Check if request still valid
        require(block.timestamp <= request.expiredAt, "ERR_CG_2");

        require(!isRequestCoverSucceed(provideCoverData.requestId), "ERR_CG_7");

        // Check if request still be able to take (not bigger than insuredSumRemaining)
        require(
            provideCoverData.fundingSum <=
                (request.insuredSum -
                    ld.requestIdToInsuredSumTaken(provideCoverData.requestId)),
            "ERR_CG_4"
        );

        // verify assetPriceInfo signature
        pool.verifyMessage(provideCoverData.assetPricing, coinSigner);

        // Collect Collateral
        CurrencyType insuredSumCurrency = request.insuredSumCurrency;
        pool.acceptAsset(
            msg.sender,
            insuredSumCurrency,
            provideCoverData.fundingSum,
            provideCoverData.assetPermit
        );

        // Deduct remaining insured sum
        uint256 insuredSumTaken = ld.requestIdToInsuredSumTaken(
            provideCoverData.requestId
        ) + provideCoverData.fundingSum;
        ld.updateRequestInsuredSumTaken(
            provideCoverData.requestId,
            insuredSumTaken
        );

        //
        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(request.insuredSumCurrency)
        );

        // minimal deposit $1000
        require(
            provideCoverData.fundingSum >= (10**insuredSumCurrencyDecimal),
            "ERR_CG_8"
        );

        // Stored Data
        CoverFunding memory booking;
        booking.requestId = provideCoverData.requestId;
        booking.funder = provideCoverData.provider;
        booking.fundingSum = provideCoverData.fundingSum;
        cd.storeBookingByTakeRequest(booking);

        // Set startAt as 0 to identified as cover not started
        InsuranceCover memory coverData;
        coverData.offerId = 0;
        coverData.requestId = provideCoverData.requestId;
        coverData.listingType = ListingType.REQUEST;
        coverData.holder = request.holder;
        coverData.insuredSum = provideCoverData.fundingSum;
        // Multiply by 10**12, 10**6 for cover qty decimals & 10**6 for neutralize division by coinPrice
        coverData.coverQty =
            (provideCoverData.fundingSum * 10**12) /
            provideCoverData.assetPricing.coinPrice;
        cd.storeCoverByTakeRequest(
            coverData,
            request.coverMonths,
            provideCoverData.provider
        );

        // either its full or partial funding, as long as its fully funded then start cover
        if (ld.isRequestFullyFunded(provideCoverData.requestId)) {
            ld.setCoverRequestFullyFundedAt(
                provideCoverData.requestId,
                block.timestamp
            );
        }
    }

    /**
     * @dev get actual state of cover request
     */
    function isRequestCoverSucceed(uint256 requestId)
        public
        view
        returns (bool state)
    {
        CoverRequest memory coverRequest = ld.getCoverRequestById(requestId);

        if (
            ld.isRequestFullyFunded(requestId) ||
            (coverRequest.insuredSumRule == InsuredSumRule.PARTIAL &&
                block.timestamp > coverRequest.expiredAt &&
                ld.isRequestReachTarget(requestId))
        ) {
            state = true;
        } else {
            state = false;
        }
    }

    /**
     * @dev calculate startAt of cover
     */
    function getStartAt(uint256 coverId) public view returns (uint256 startAt) {
        InsuranceCover memory cover = cd.getCoverById(coverId);

        if (cover.listingType == ListingType.REQUEST) {
            CoverRequest memory coverRequest = ld.getCoverRequestById(
                cover.requestId
            );

            if (ld.isRequestFullyFunded(cover.requestId)) {
                startAt = ld.coverRequestFullyFundedAt(cover.requestId);
            } else if (
                coverRequest.insuredSumRule == InsuredSumRule.PARTIAL &&
                block.timestamp > coverRequest.expiredAt &&
                ld.isRequestReachTarget(cover.requestId)
            ) {
                startAt = coverRequest.expiredAt;
            }
        } else if (cover.listingType == ListingType.OFFER) {
            startAt = cd.insuranceCoverStartAt(coverId);
        }
    }

    /**
     * @dev calculate endAt for cover
     */
    function getEndAt(uint256 coverId) external view returns (uint256 endAt) {
        InsuranceCover memory cover = cd.getCoverById(coverId);
        uint8 coverMonths = 0;
        if (cover.listingType == ListingType.REQUEST) {
            CoverRequest memory coverRequest = ld.getCoverRequestById(
                cover.requestId
            );
            coverMonths = coverRequest.coverMonths;
        } else if (cover.listingType == ListingType.OFFER) {
            // CoverOffer memory coverOffer = ld.getCoverOfferById(cover.offerId);
            coverMonths = cd.getCoverMonths(coverId);
        }
        return (getStartAt(coverId) + (uint256(coverMonths) * 30 days));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ListingData} from "../Data/ListingData.sol";
import {ClaimData} from "../Data/ClaimData.sol";
import {PlatformData} from "../Data/PlatformData.sol";
import {Master} from "../Master/Master.sol";
import {CoverGateway} from "./CoverGateway.sol";
import {CoverData} from "../Data/CoverData.sol";
import {Pool} from "../Capital/Pool.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ListingGateway is Master {
    CoverData private cd;
    ListingData private ld;
    ClaimData private claimData;
    CoverGateway private coverGateway;
    Pool private pool;
    PlatformData private platformData;
    ERC20Burnable internal infiToken;
    address public coinSigner;

    /**
    @dev Check balance of member/sender, minimal have 5000 Infi token. Used in Create Offer, Take Offer and Take Request
    @param _from member/sender's address
    @param _tokenAmount amount of token that used for create listing (will be 0 for take offer and take request)
     */
    modifier minimumBalance(address _from, uint256 _tokenAmount) {
        uint256 tokenAfterTransfer = infiToken.balanceOf(_from);
        uint256 tokenBeforeTransfer = tokenAfterTransfer + _tokenAmount;
        uint256 infiTokenDecimal = 18;
        require(
            tokenBeforeTransfer >= (5000 * (10**infiTokenDecimal)),
            "ERR_AUTH_4"
        );
        _;
    }

    /**
     @dev Tier system for check capability of member
     @param _from member's address
     @param _tokenAmount amount of infi token that transfered
     @param _insuredSum value of asset in USD
     @param _currencyType insuredsum's currency
     */
    modifier verifyMemberLevel(
        address _from,
        uint256 _tokenAmount,
        uint256 _insuredSum,
        CurrencyType _currencyType
    ) {
        uint256 tokenAfterTransfer = infiToken.balanceOf(_from);
        uint256 tokenBeforeTransfer = tokenAfterTransfer + _tokenAmount;
        uint256 infiTokenDecimal = 18;
        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(_currencyType)
        );

        if (_insuredSum <= (10000 * (10**insuredSumCurrencyDecimal))) {
            // Bronze
            require(
                tokenBeforeTransfer >= (5000 * (10**infiTokenDecimal)),
                "ERR_AUTH_4"
            );
        } else if (_insuredSum <= (50000 * (10**insuredSumCurrencyDecimal))) {
            // Silver
            require(
                tokenBeforeTransfer >= (10000 * (10**infiTokenDecimal)),
                "ERR_AUTH_4"
            );
        } else if (_insuredSum <= (100000 * (10**insuredSumCurrencyDecimal))) {
            // Gold
            require(
                tokenBeforeTransfer >= (25000 * (10**infiTokenDecimal)),
                "ERR_AUTH_4"
            );
        } else if (_insuredSum > (100000 * (10**insuredSumCurrencyDecimal))) {
            // Diamond
            require(
                tokenBeforeTransfer >= (50000 * (10**infiTokenDecimal)),
                "ERR_AUTH_4"
            );
        }

        _;
    }

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        ld = ListingData(cg.getLatestAddress("LD"));
        infiToken = ERC20Burnable(cg.infiTokenAddr());
        coverGateway = CoverGateway(cg.getLatestAddress("CG"));
        cd = CoverData(cg.getLatestAddress("CD"));
        pool = Pool(cg.getLatestAddress("PL"));
        coinSigner = cg.getLatestAddress("CS");
        claimData = ClaimData(cg.getLatestAddress("CM"));
        platformData = PlatformData(cg.getLatestAddress("PD"));
    }

    /**
     * @dev Called when member create a new Cover Request Listing, to stored listing data
     */
    function createCoverRequest(
        address from,
        uint256 value,
        bytes memory payData
    ) external onlyInternal {
        CreateCoverRequestData memory payload = abi.decode(
            payData,
            (CreateCoverRequestData)
        );

        require(payload.request.holder == from, "ERR_LG_1");

        require(
            payload.request.coverMonths >= 1 &&
                payload.request.coverMonths <= 12,
            "ERR_LG_2"
        ); // Validate Cover Period

        // expired at must between now and next 14 days
        // add 1 day as buffer, in case transaction pending on mempool
        require(
            payload.request.expiredAt >= block.timestamp &&
                payload.request.expiredAt <=
                (block.timestamp + (14 * 1 days) + 1 days),
            "ERR_LG_3"
        );

        // Set Listing Fee
        uint256 listingFee = pool.getListingFee(
            payload.request.insuredSumCurrency,
            payload.request.insuredSum,
            payload.feePricing.coinPrice,
            payload.roundId
        );

        // Verify listing fee amount
        require(listingFee == value, "ERR_LG_4");

        // Transfer 50% of listing fee to dev wallet and burn 50%
        pool.transferAndBurnInfi(listingFee);

        // Verify Coin Info Signature
        pool.verifyMessage(payload.assetPricing, coinSigner); // Validate signature Asset Price
        pool.verifyMessage(payload.feePricing, coinSigner); // Validate signature Fee Price

        // Transfer Premium to smart contract
        pool.acceptAsset(
            from,
            payload.request.insuredSumCurrency,
            payload.request.premiumSum,
            payload.premiumPermit
        );

        // verify and stored data
        _createRequest(payload, from, value);
    }

    function _createRequest(
        CreateCoverRequestData memory payload,
        address from,
        uint256 value
    )
        internal
        verifyMemberLevel(
            from,
            value,
            payload.request.insuredSum,
            payload.request.insuredSumCurrency
        )
    {
        // Set up value for Request Cover
        if (payload.request.insuredSumRule == InsuredSumRule.FULL) {
            uint8 decimal = cg.getCurrencyDecimal(
                uint8(payload.request.insuredSumCurrency)
            );
            uint256 tolerance = 2 * (10**decimal); // tolerance 2 tokens
            payload.request.insuredSumTarget =
                payload.request.insuredSum -
                tolerance;
        } else if (payload.request.insuredSumRule == InsuredSumRule.PARTIAL) {
            payload.request.insuredSumTarget = payload.request.insuredSum / 4;
        }
        // Stored data listing
        ld.storedRequest(
            payload.request,
            payload.assetPricing,
            payload.feePricing,
            from
        );
    }

    /**
     * @dev Called when member create a new Cover Offer Listing, to stored listing data
     */

    function createCoverOffer(
        address from,
        uint256 value,
        bytes memory payData
    ) external onlyInternal {
        CreateCoverOfferData memory payload = abi.decode(
            payData,
            (CreateCoverOfferData)
        );

        // expired at must between now and next 1 year
        // add 1 day as buffer, in case transaction pending on mempool
        require(
            payload.offer.expiredAt >= block.timestamp &&
                payload.offer.expiredAt <=
                (block.timestamp + (366 days) + 1 days),
            "ERR_LG_3"
        );

        // verify funder
        require(payload.offer.funder == from, "ERR_LG_1");

        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(payload.offer.insuredSumCurrency)
        );

        // minimal deposit $1000
        require(
            payload.offer.insuredSum >= (1000 * 10**insuredSumCurrencyDecimal),
            "ERR_LG_5"
        );

        // Set Listing Fee
        uint256 listingFee = pool.getListingFee(
            payload.offer.insuredSumCurrency,
            payload.offer.insuredSum,
            payload.feePricing.coinPrice,
            payload.roundId
        );

        // Note : verify insured sum worth 1000$

        // Verify listing fee amount
        require(listingFee == value, "ERR_LG_4");

        // Transfer 50% of listing fee to dev wallet and burn 50%
        pool.transferAndBurnInfi(listingFee);

        // Verify Coin Info Signature
        pool.verifyMessage(payload.feePricing, coinSigner); // Validate signature Fee Price
        pool.verifyMessage(payload.assetPricing, coinSigner); // Validate signature Asset Price

        // Transfer collateral to current smart contract
        pool.acceptAsset(
            from,
            payload.offer.insuredSumCurrency,
            payload.offer.insuredSum,
            payload.fundingPermit
        );

        // verify and stored data
        _createOffer(payload, from, value);
    }

    function _createOffer(
        CreateCoverOfferData memory payload,
        address from,
        uint256 value
    ) internal minimumBalance(from, value) {
        // Stored data listing
        ld.storedOffer(
            payload.offer,
            payload.feePricing,
            payload.assetPricing,
            payload.depositPeriod,
            from
        );
    }

    /**
     * @dev get list of id(s) of active cover offer
     */
    function getListActiveCoverOffer()
        external
        view
        returns (uint256 listLength, uint256[] memory coverOfferIds)
    {
        // Because "push" is not available in uint256[] memory outside of storage
        // Need to create workaround for push to array
        uint256 coverOfferLength = ld.getCoverOfferLength();
        coverOfferIds = new uint256[](coverOfferLength);
        uint256 iteration = 0;

        for (uint256 i = 0; i < coverOfferLength; i++) {
            CoverOffer memory coverOffer = ld.getCoverOfferById(i);
            if (coverOffer.expiredAt >= block.timestamp) {
                coverOfferIds[iteration] = i;
                iteration = iteration + 1;
            }
        }

        return (iteration, coverOfferIds);
    }

    /**
     * @dev get insured sum taken, return value will based on calculation of covers
     */
    function getInsuredSumTakenOfCoverOffer(uint256 coverOfferId)
        external
        view
        returns (uint256 insuredSumTaken)
    {
        uint256[] memory listCoverIds = cd.getCoversByOfferId(coverOfferId);

        for (uint256 i = 0; i < listCoverIds.length; i++) {
            if (block.timestamp < coverGateway.getEndAt(listCoverIds[i])) {
                InsuranceCover memory cover = cd.getCoverById(listCoverIds[i]);
                // Cover still active
                insuredSumTaken += cover.insuredSum;
            } else {
                // Cover not active, check the payout for the cover
                insuredSumTaken += claimData.coverToPayout(listCoverIds[i]);
            }
        }
    }

    function getChainlinkPrice(uint8 currencyType)
        external
        view
        returns (
            uint80 roundId,
            int256 price,
            uint8 decimals
        )
    {
        require(currencyType < uint8(CurrencyType.END_ENUM), "ERR_CHNLNK_2");
        address priceFeedAddr = platformData.getOraclePriceFeedAddress(
            cg.getCurrencyName(currencyType)
        );
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        (roundId, price, , , ) = priceFeed.latestRoundData();
        decimals = priceFeed.decimals();
        return (roundId, price, decimals);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IConfig {
    /**
     * @dev return address of Infi Token
     */
    function infiTokenAddr() external returns (address);

    /**
     * @dev return address of contract based on Initial Contract Name
     */
    function getLatestAddress(bytes2 _contractName)
        external
        returns (address payable contractAddress);

    /**
     * @dev check whether caller is internal smart contract
     * @dev internal smart contracts are smart contracts that used on Infi Project
     */
    function isInternal(address _add) external returns (bool);

    /**
     * @dev get decimals of given currency code/number
     */
    function getCurrencyDecimal(uint8 _currencyType)
        external
        view
        returns (uint8);

    /**
     * @dev get name of given currency code/number
     */
    function getCurrencyName(uint8 _currencyType)
        external
        view
        returns (string memory);

    function maxDevaluation() external view returns (uint256);

    function monitoringPeriod() external view returns (uint256);

    function maxPayoutPeriod() external view returns (uint256);

    function validationPreviousPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IConfig} from "./IConfig.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract Master {
    // Used publicly
    IConfig internal cg;
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    // Storage and Payload
    enum CoverType {
        SMART_PROTOCOL_FAILURE,
        STABLECOIN_DEVALUATION,
        CUSTODIAN_FAILURE,
        RUGPULL_LIQUIDITY_SCAM
    }
    enum CurrencyType {
        USDT,
        USDC,
        DAI,
        END_ENUM
    }
    enum InsuredSumRule {
        PARTIAL,
        FULL
    }
    enum ListingType {
        REQUEST,
        OFFER
    }

    enum ClaimState {
        MONITORING,
        INVALID,
        VALID,
        INVALID_AFTER_EXPIRED,
        VALID_AFTER_EXPIRED
    }

    // For passing parameter and store state variables
    struct CoverRequest {
        uint256 coverQty; // coverQty decimals depends on coinIdToDecimals mapping
        uint8 coverMonths; // represent month value 1-12
        uint256 insuredSum;
        uint256 insuredSumTarget; // if full funding : insuredSum - 2$
        CurrencyType insuredSumCurrency;
        uint256 premiumSum;
        CurrencyType premiumCurrency;
        uint256 expiredAt; // now + 14 days
        string coinId; // CoinGecko
        CoverLimit coverLimit;
        InsuredSumRule insuredSumRule;
        address holder; // may validate or not validate if same as msg.sender
    }

    // For passing parameter and store state variables
    struct CoverOffer {
        uint8 minCoverMonths; // represent month value 1-12 (expiredAt + 1 month - now >= minCoverMonths)
        uint256 insuredSum;
        CurrencyType insuredSumCurrency;
        uint256 premiumCostPerMonth; // $0.02 per $1 insured per Month (2000) a.k.a Premium Cost Per month per asset
        CurrencyType premiumCurrency;
        // IMPORTANT: max date for buying cover = expiredAt + 1 month
        uint256 expiredAt; // despositEndDate - 14 days beforeDepositEndDate
        string coinId; // CoinGecko
        CoverLimit coverLimit;
        InsuredSumRule insuredSumRule;
        address funder; // may validate or not validate if same as msg.sender
    }

    // Storage struct
    // Relationship: CoverCoverOffer ||--< Cover
    // Relationship: CoverRequest ||--< Cover
    // Relationship: One cover can have only one offer
    // Relationship: One cover can have only one request
    struct InsuranceCover {
        // type computed from (offerId != 0) or (requestId != 0)

        // If BuyCover (take offer)
        uint256 offerId; // from BuyCover.offerId
        // If CoverFunding (take request)
        uint256 requestId; // from CoverFunding.requestId
        // uint[] provideIds;

        ListingType listingType;
        // will validate claimSender
        address holder; // from BuyCover.buyer or CoverRequest.buyer
        // will validate maximum claimSum
        uint256 insuredSum; // from BuyCover.insuredSum or sum(CoverFunding.fundingSum)
        // will validate maximum claimQuantity
        uint256 coverQty; // from BuyCover.coverQty or CoverRequest.coverQty
    }

    // Storage: "Booking" object when take request
    // Relationship: CoverRequest ||--< CoverFunding
    struct CoverFunding {
        uint256 requestId;
        address funder;
        // insurance data:
        uint256 fundingSum; // part or portion of total insuredSum
    }

    // Payload: object when take offer
    // Virtual struct/type for payload (type of payloadBuyCover)
    struct BuyCover {
        uint256 offerId;
        address buyer;
        // insurance data:
        uint8 coverMonths; // represent month value 1-12
        uint256 coverQty; // coverQty decimals depends on coinIdToDecimals mapping
        uint256 insuredSum; // need validation : coverQty * assetPricing.coinPrice
        CoinPricingInfo assetPricing;
        bytes premiumPermit;
    }

    // Payload: object when take request
    // Virtual struct/type for payload (type of payloadBuyCover)
    struct ProvideCover {
        uint256 requestId;
        address provider;
        // insurance data:
        uint256 fundingSum;
        CoinPricingInfo assetPricing;
        bytes assetPermit;
    }

    // For passing Coin and Listing Fee info, required for validation
    struct CoinPricingInfo {
        string coinId;
        string coinSymbol;
        uint256 coinPrice; // decimals 6
        uint256 lastUpdatedAt;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    struct CoverLimit {
        CoverType coverType;
        uint256[] territoryIds; // Platform Id, Price Feed Id, Custodian Id , (Dex Pool Id not Yet implemented)
    }

    struct Platform {
        string name;
        string website;
    }

    struct Oracle {
        string name;
        string website;
    }

    struct PriceFeed {
        uint256 oracleId;
        uint256 chainId;
        uint8 decimals;
        address proxyAddress;
    }

    struct Custodian {
        string name;
        string website;
    }

    struct EIP2612Permit {
        address owner;
        uint256 value;
        address spender;
        uint256 deadline;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    struct DAIPermit {
        address holder;
        address spender;
        uint256 nonce;
        uint256 expiry;
        bool allowed;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    struct CreateCoverRequestData {
        CoverRequest request; //
        CoinPricingInfo assetPricing; //
        CoinPricingInfo feePricing; //
        uint80 roundId; // insured sum to usd for calculate fee price
        bytes premiumPermit; // for transfer DAI, USDT, USDC
    }

    struct CreateCoverOfferData {
        CoverOffer offer; //
        CoinPricingInfo assetPricing;
        uint8 depositPeriod;
        CoinPricingInfo feePricing; //
        uint80 roundId; // insured sum to usd for calculate fee price
        bytes fundingPermit; // for transfer DAI, USDT, USDC
    }

    // Structs
    struct Claim {
        uint80 roundId; // round id that represent start of dropping value
        uint256 claimTime;
        uint256 payout;
        ClaimState state;
    }

    struct CollectiveClaim {
        uint80 roundId; // round id that represent start of dropping value
        uint256 claimTime;
        uint256 payout;
        ClaimState state;
    }

    // Modifier
    modifier onlyInternal() {
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
        _;
    }

    /**
     * @dev change config contract address
     * @param configAddress is the new address
     */
    function changeConfigAddress(address configAddress) external {
        // Only admin allowed to call this function
        if (address(cg) != address(0)) {
            require(
                IAccessControl(address(cg)).hasRole(
                    DEFAULT_ADMIN_ROLE,
                    msg.sender
                ),
                "ERR_AUTH_1"
            );
        }
        // Change config address
        cg = IConfig(configAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}