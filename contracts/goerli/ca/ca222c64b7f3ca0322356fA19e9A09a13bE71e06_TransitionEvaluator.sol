// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Registry is Ownable {
    // require() error messages
    string private constant REQ_BAD_ASSET = "invalid asset";
    string private constant REQ_BAD_ST = "invalid strategy";

    // Map asset addresses to indexes.
    // asset with index 1 is CELR as the platform token
    mapping(address => uint32) public assetAddressToIndex;
    mapping(uint32 => address) public assetIndexToAddress;
    uint32 public numAssets = 0;

    // Valid strategies.
    mapping(address => uint32) public strategyAddressToIndex;
    mapping(uint32 => address) public strategyIndexToAddress;
    uint32 public numStrategies = 0;

    event AssetRegistered(address asset, uint32 assetId);
    event StrategyRegistered(address strategy, uint32 strategyId);
    event StrategyUpdated(address previousStrategy, address newStrategy, uint32 strategyId);

    /**
     * @notice Register a asset
     * @param _asset The asset token address;
     */
    function registerAsset(address _asset) external onlyOwner {
        require(_asset != address(0), REQ_BAD_ASSET);
        require(assetAddressToIndex[_asset] == 0, REQ_BAD_ASSET);

        // Register asset with an index >= 1 (zero is reserved).
        numAssets++;
        assetAddressToIndex[_asset] = numAssets;
        assetIndexToAddress[numAssets] = _asset;

        emit AssetRegistered(_asset, numAssets);
    }

    /**
     * @notice Register a strategy
     * @param _strategy The strategy contract address;
     */
    function registerStrategy(address _strategy) external onlyOwner {
        require(_strategy != address(0), REQ_BAD_ST);
        require(strategyAddressToIndex[_strategy] == 0, REQ_BAD_ST);

        // Register strategy with an index >= 1 (zero is reserved).
        numStrategies++;
        strategyAddressToIndex[_strategy] = numStrategies;
        strategyIndexToAddress[numStrategies] = _strategy;

        emit StrategyRegistered(_strategy, numStrategies);
    }

    /**
     * @notice Update the address of an existing strategy
     * @param _strategy The strategy contract address;
     * @param _strategyId The strategy ID;
     */
    function updateStrategy(address _strategy, uint32 _strategyId) external onlyOwner {
        require(_strategy != address(0), REQ_BAD_ST);
        require(strategyIndexToAddress[_strategyId] != address(0), REQ_BAD_ST);

        address previousStrategy = strategyIndexToAddress[_strategyId];
        strategyAddressToIndex[previousStrategy] = 0;
        strategyAddressToIndex[_strategy] = _strategyId;
        strategyIndexToAddress[_strategyId] = _strategy;

        emit StrategyUpdated(previousStrategy, _strategy, _strategyId);
    }
}

// SPDX-License-Identifier: MIT

// 1st part of the transition applier due to contract size restrictions

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/* Internal Imports */
import {DataTypes as dt} from "./libraries/DataTypes.sol";
import {Transitions as tn} from "./libraries/Transitions.sol";
import "./libraries/ErrMsg.sol";
import "./Registry.sol";
import "./strategies/interfaces/IStrategy.sol";

contract TransitionApplier1 {
    uint128 public constant UINT128_MAX = 2**128 - 1;

    /**********************
     * External Functions *
     **********************/

    /**
     * @notice Apply a DepositTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @return new account info after applying the disputed transition
     */
    function applyDepositTransition(dt.DepositTransition memory _transition, dt.AccountInfo memory _accountInfo)
        public
        pure
        returns (dt.AccountInfo memory)
    {
        require(_transition.account != address(0), ErrMsg.REQ_BAD_ACCT);
        if (_accountInfo.account == address(0)) {
            // first time deposit of this account
            require(_accountInfo.accountId == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfo.idleAssets.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfo.shares.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfo.pending.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfo.timestamp == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            _accountInfo.account = _transition.account;
            _accountInfo.accountId = _transition.accountId;
        } else {
            require(_accountInfo.account == _transition.account, ErrMsg.REQ_BAD_ACCT);
            require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        }

        uint32 assetId = _transition.assetId;
        tn.adjustAccountIdleAssetEntries(_accountInfo, assetId);
        _accountInfo.idleAssets[assetId] += _transition.amount;

        return _accountInfo;
    }

    /**
     * @notice Apply a WithdrawTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account and global info after applying the disputed transition
     */
    function applyWithdrawTransition(
        dt.WithdrawTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.GlobalInfo memory _globalInfo
    ) public pure returns (dt.AccountInfo memory, dt.GlobalInfo memory) {
        bytes32 txHash =
            keccak256(
                abi.encodePacked(
                    _transition.transitionType,
                    _transition.account,
                    _transition.assetId,
                    _transition.amount,
                    _transition.fee,
                    _transition.timestamp
                )
            );
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(txHash), _transition.v, _transition.r, _transition.s) ==
                _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );

        require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        _accountInfo.timestamp = _transition.timestamp;

        _accountInfo.idleAssets[_transition.assetId] -= _transition.amount;
        tn.addProtoFee(_globalInfo, _transition.assetId, _transition.fee);

        return (_accountInfo, _globalInfo);
    }

    /**
     * @notice Apply a BuyTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @return new account, strategy info, and global info after applying the disputed transition
     */
    function applyBuyTransition(
        dt.BuyTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.StrategyInfo memory _strategyInfo,
        Registry _registry
    ) public view returns (dt.AccountInfo memory, dt.StrategyInfo memory) {
        bytes32 txHash =
            keccak256(
                abi.encodePacked(
                    _transition.transitionType,
                    _transition.strategyId,
                    _transition.amount,
                    _transition.maxSharePrice,
                    _transition.fee,
                    _transition.timestamp
                )
            );
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(txHash), _transition.v, _transition.r, _transition.s) ==
                _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );

        require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        _accountInfo.timestamp = _transition.timestamp;

        if (_strategyInfo.assetId == 0) {
            // first time commit of new strategy
            require(_strategyInfo.shareSupply == 0, ErrMsg.REQ_ST_NOT_EMPTY);
            require(_strategyInfo.nextAggregateId == 0, ErrMsg.REQ_ST_NOT_EMPTY);
            require(_strategyInfo.lastExecAggregateId == 0, ErrMsg.REQ_ST_NOT_EMPTY);
            require(_strategyInfo.pending.length == 0, ErrMsg.REQ_ST_NOT_EMPTY);

            address strategyAddr = _registry.strategyIndexToAddress(_transition.strategyId);
            address assetAddr = IStrategy(strategyAddr).getAssetAddress();
            _strategyInfo.assetId = _registry.assetAddressToIndex(assetAddr);
        }
        _accountInfo.idleAssets[_strategyInfo.assetId] -= _transition.amount;

        uint256 npend = _strategyInfo.pending.length;
        if (npend == 0 || _strategyInfo.pending[npend - 1].aggregateId != _strategyInfo.nextAggregateId) {
            dt.PendingStrategyInfo[] memory pends = new dt.PendingStrategyInfo[](npend + 1);
            for (uint32 i = 0; i < npend; i++) {
                pends[i] = _strategyInfo.pending[i];
            }
            pends[npend].aggregateId = _strategyInfo.nextAggregateId;
            pends[npend].maxSharePriceForBuy = _transition.maxSharePrice;
            pends[npend].minSharePriceForSell = 0;
            npend++;
            _strategyInfo.pending = pends;
        } else if (_strategyInfo.pending[npend - 1].maxSharePriceForBuy > _transition.maxSharePrice) {
            _strategyInfo.pending[npend - 1].maxSharePriceForBuy = _transition.maxSharePrice;
        }

        uint256 buyAmount = _transition.amount;
        (bool isCelr, uint256 fee) = tn.getFeeInfo(_transition.fee);
        if (isCelr) {
            _accountInfo.idleAssets[1] -= fee;
        } else {
            buyAmount -= fee;
        }

        _strategyInfo.pending[npend - 1].buyAmount += buyAmount;

        _adjustAccountPendingEntries(_accountInfo, _transition.strategyId, _strategyInfo.nextAggregateId);
        npend = _accountInfo.pending[_transition.strategyId].length;
        _accountInfo.pending[_transition.strategyId][npend - 1].buyAmount += buyAmount;
        if (isCelr) {
            _accountInfo.pending[_transition.strategyId][npend - 1].celrFees += fee;
        } else {
            _accountInfo.pending[_transition.strategyId][npend - 1].buyFees += fee;
        }

        return (_accountInfo, _strategyInfo);
    }

    /**
     * @notice Apply a SellTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @return new account, strategy info, and global info after applying the disputed transition
     */
    function applySellTransition(
        dt.SellTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.StrategyInfo memory _strategyInfo
    ) external pure returns (dt.AccountInfo memory, dt.StrategyInfo memory) {
        bytes32 txHash =
            keccak256(
                abi.encodePacked(
                    _transition.transitionType,
                    _transition.strategyId,
                    _transition.shares,
                    _transition.minSharePrice,
                    _transition.fee,
                    _transition.timestamp
                )
            );
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(txHash), _transition.v, _transition.r, _transition.s) ==
                _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );

        require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        require(_strategyInfo.assetId > 0, ErrMsg.REQ_BAD_ST);
        _accountInfo.timestamp = _transition.timestamp;

        uint256 npend = _strategyInfo.pending.length;
        if (npend == 0 || _strategyInfo.pending[npend - 1].aggregateId != _strategyInfo.nextAggregateId) {
            dt.PendingStrategyInfo[] memory pends = new dt.PendingStrategyInfo[](npend + 1);
            for (uint32 i = 0; i < npend; i++) {
                pends[i] = _strategyInfo.pending[i];
            }
            pends[npend].aggregateId = _strategyInfo.nextAggregateId;
            pends[npend].maxSharePriceForBuy = UINT128_MAX;
            pends[npend].minSharePriceForSell = _transition.minSharePrice;
            npend++;
            _strategyInfo.pending = pends;
        } else if (_strategyInfo.pending[npend - 1].minSharePriceForSell < _transition.minSharePrice) {
            _strategyInfo.pending[npend - 1].minSharePriceForSell = _transition.minSharePrice;
        }

        (bool isCelr, uint256 fee) = tn.getFeeInfo(_transition.fee);
        if (isCelr) {
            _accountInfo.idleAssets[1] -= fee;
        }

        uint32 stId = _transition.strategyId;
        _accountInfo.shares[stId] -= _transition.shares;
        _strategyInfo.pending[npend - 1].sellShares += _transition.shares;

        _adjustAccountPendingEntries(_accountInfo, stId, _strategyInfo.nextAggregateId);
        npend = _accountInfo.pending[stId].length;
        _accountInfo.pending[stId][npend - 1].sellShares += _transition.shares;
        if (isCelr) {
            _accountInfo.pending[stId][npend - 1].celrFees += fee;
        } else {
            _accountInfo.pending[stId][npend - 1].sellFees += fee;
        }

        return (_accountInfo, _strategyInfo);
    }

    /**
     * @notice Apply a SettlementTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account, strategy info, and global info after applying the disputed transition
     */
    function applySettlementTransition(
        dt.SettlementTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.StrategyInfo memory _strategyInfo,
        dt.GlobalInfo memory _globalInfo
    )
        external
        pure
        returns (
            dt.AccountInfo memory,
            dt.StrategyInfo memory,
            dt.GlobalInfo memory
        )
    {
        uint32 stId = _transition.strategyId;
        uint32 assetId = _strategyInfo.assetId;
        uint64 aggrId = _transition.aggregateId;
        require(aggrId <= _strategyInfo.lastExecAggregateId, ErrMsg.REQ_BAD_AGGR);
        require(_strategyInfo.pending.length > 0, ErrMsg.REQ_NO_PEND);
        require(aggrId == _strategyInfo.pending[0].aggregateId, ErrMsg.REQ_BAD_AGGR);
        require(_accountInfo.pending.length > stId, ErrMsg.REQ_BAD_ST);
        require(_accountInfo.pending[stId].length > 0, ErrMsg.REQ_NO_PEND);
        require(aggrId == _accountInfo.pending[stId][0].aggregateId, ErrMsg.REQ_BAD_AGGR);

        dt.PendingStrategyInfo memory stPend = _strategyInfo.pending[0];
        dt.PendingAccountInfo memory acctPend = _accountInfo.pending[stId][0];

        if (stPend.executionSucceed) {
            uint256 assetRefund = _transition.assetRefund;
            uint256 celrRefund = _transition.celrRefund;
            if (acctPend.buyAmount > 0) {
                tn.adjustAccountShareEntries(_accountInfo, stId);
                uint256 shares = (acctPend.buyAmount * stPend.sharesFromBuy) / stPend.buyAmount;
                _accountInfo.shares[stId] += shares;
                stPend.unsettledBuyAmount -= acctPend.buyAmount;
            }
            if (acctPend.sellShares > 0) {
                tn.adjustAccountIdleAssetEntries(_accountInfo, assetId);
                uint256 amount = (acctPend.sellShares * stPend.amountFromSell) / stPend.sellShares;
                uint256 fee = acctPend.sellFees;
                if (fee < assetRefund) {
                    assetRefund -= fee;
                    fee = 0;
                } else {
                    fee -= assetRefund;
                    assetRefund = 0;
                }
                if (amount < fee) {
                    fee = amount;
                }
                amount -= fee;
                tn.addProtoFee(_globalInfo, assetId, fee);
                _accountInfo.idleAssets[assetId] += amount;
                stPend.unsettledSellShares -= acctPend.sellShares;
            }
            _accountInfo.idleAssets[assetId] += assetRefund;
            tn.addProtoFee(_globalInfo, assetId, acctPend.buyFees - assetRefund);
            _accountInfo.idleAssets[1] += celrRefund;
            tn.addProtoFee(_globalInfo, 1, acctPend.celrFees - celrRefund);
        } else {
            if (acctPend.buyAmount > 0) {
                tn.adjustAccountIdleAssetEntries(_accountInfo, assetId);
                _accountInfo.idleAssets[assetId] += acctPend.buyAmount;
                stPend.unsettledBuyAmount -= acctPend.buyAmount;
            }
            if (acctPend.sellShares > 0) {
                tn.adjustAccountShareEntries(_accountInfo, stId);
                _accountInfo.shares[stId] += acctPend.sellShares;
                stPend.unsettledSellShares -= acctPend.sellShares;
            }
            _accountInfo.idleAssets[assetId] += acctPend.buyFees;
            _accountInfo.idleAssets[1] += acctPend.celrFees;
        }

        _popHeadAccountPendingEntries(_accountInfo, stId);
        if (stPend.unsettledBuyAmount == 0 && stPend.unsettledSellShares == 0) {
            _popHeadStrategyPendingEntries(_strategyInfo);
        }

        return (_accountInfo, _strategyInfo, _globalInfo);
    }

    /**
     * @notice Apply a TransferAssetTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition (source of the transfer).
     * @param _accountInfoDest The involved destination account from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account info for both accounts, and global info after applying the disputed transition
     */
    function applyAssetTransferTransition(
        dt.TransferAssetTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.AccountInfo memory _accountInfoDest,
        dt.GlobalInfo memory _globalInfo
    )
        external
        pure
        returns (
            dt.AccountInfo memory,
            dt.AccountInfo memory,
            dt.GlobalInfo memory
        )
    {
        bytes32 txHash =
            keccak256(
                abi.encodePacked(
                    _transition.transitionType,
                    _transition.toAccount,
                    _transition.assetId,
                    _transition.amount,
                    _transition.fee,
                    _transition.timestamp
                )
            );
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(txHash), _transition.v, _transition.r, _transition.s) ==
                _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );
        require(_accountInfo.accountId == _transition.fromAccountId, ErrMsg.REQ_BAD_ACCT);

        if (_accountInfoDest.account == address(0)) {
            // transfer to a new account
            require(_accountInfoDest.accountId == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.idleAssets.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.shares.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.pending.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.timestamp == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            _accountInfoDest.account = _transition.toAccount;
            _accountInfoDest.accountId = _transition.toAccountId;
        } else {
            require(_accountInfoDest.account == _transition.toAccount, ErrMsg.REQ_BAD_ACCT);
            require(_accountInfoDest.accountId == _transition.toAccountId, ErrMsg.REQ_BAD_ACCT);
        }

        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        _accountInfo.timestamp = _transition.timestamp;

        uint32 assetId = _transition.assetId;
        uint256 amount = _transition.amount;
        (bool isCelr, uint256 fee) = tn.getFeeInfo(_transition.fee);
        if (isCelr) {
            _accountInfo.idleAssets[1] -= fee;
            tn.updateOpFee(_globalInfo, true, 1, fee);
        } else {
            amount -= fee;
            tn.updateOpFee(_globalInfo, true, assetId, fee);
        }

        tn.adjustAccountIdleAssetEntries(_accountInfoDest, assetId);
        _accountInfo.idleAssets[assetId] -= _transition.amount;
        _accountInfoDest.idleAssets[assetId] += amount;

        return (_accountInfo, _accountInfoDest, _globalInfo);
    }

    /**
     * @notice Apply a TransferShareTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition (source of the transfer).
     * @param _accountInfoDest The involved destination account from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account info for both accounts, and global info after applying the disputed transition
     */
    function applyShareTransferTransition(
        dt.TransferShareTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.AccountInfo memory _accountInfoDest,
        dt.GlobalInfo memory _globalInfo
    )
        external
        pure
        returns (
            dt.AccountInfo memory,
            dt.AccountInfo memory,
            dt.GlobalInfo memory
        )
    {
        bytes32 txHash =
            keccak256(
                abi.encodePacked(
                    _transition.transitionType,
                    _transition.toAccount,
                    _transition.strategyId,
                    _transition.shares,
                    _transition.fee,
                    _transition.timestamp
                )
            );
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(txHash), _transition.v, _transition.r, _transition.s) ==
                _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );
        require(_accountInfo.accountId == _transition.fromAccountId, ErrMsg.REQ_BAD_ACCT);

        if (_accountInfoDest.account == address(0)) {
            // transfer to a new account
            require(_accountInfoDest.accountId == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.idleAssets.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.shares.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.pending.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.timestamp == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            _accountInfoDest.account = _transition.toAccount;
            _accountInfoDest.accountId = _transition.toAccountId;
        } else {
            require(_accountInfoDest.account == _transition.toAccount, ErrMsg.REQ_BAD_ACCT);
            require(_accountInfoDest.accountId == _transition.toAccountId, ErrMsg.REQ_BAD_ACCT);
        }

        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        _accountInfo.timestamp = _transition.timestamp;

        uint32 stId = _transition.strategyId;
        uint256 shares = _transition.shares;
        (bool isCelr, uint256 fee) = tn.getFeeInfo(_transition.fee);
        if (isCelr) {
            _accountInfo.idleAssets[1] -= fee;
            tn.updateOpFee(_globalInfo, true, 1, fee);
        } else {
            shares -= fee;
            tn.updateOpFee(_globalInfo, false, stId, fee);
        }

        tn.adjustAccountShareEntries(_accountInfoDest, stId);
        _accountInfo.shares[stId] -= _transition.shares;
        _accountInfoDest.shares[stId] += shares;

        return (_accountInfo, _accountInfoDest, _globalInfo);
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Helper to expand and initialize the 2D array of account pending entries per strategy and aggregate IDs.
     */
    function _adjustAccountPendingEntries(
        dt.AccountInfo memory _accountInfo,
        uint32 stId,
        uint64 aggrId
    ) private pure {
        uint32 n = uint32(_accountInfo.pending.length);
        if (n <= stId) {
            dt.PendingAccountInfo[][] memory pends = new dt.PendingAccountInfo[][](stId + 1);
            for (uint32 i = 0; i < n; i++) {
                pends[i] = _accountInfo.pending[i];
            }
            for (uint32 i = n; i < stId; i++) {
                pends[i] = new dt.PendingAccountInfo[](0);
            }
            pends[stId] = new dt.PendingAccountInfo[](1);
            pends[stId][0].aggregateId = aggrId;
            _accountInfo.pending = pends;
        } else {
            uint32 npend = uint32(_accountInfo.pending[stId].length);
            if (npend == 0 || _accountInfo.pending[stId][npend - 1].aggregateId != aggrId) {
                dt.PendingAccountInfo[] memory pends = new dt.PendingAccountInfo[](npend + 1);
                for (uint32 i = 0; i < npend; i++) {
                    pends[i] = _accountInfo.pending[stId][i];
                }
                pends[npend].aggregateId = aggrId;
                _accountInfo.pending[stId] = pends;
            }
        }
    }

    /**
     * Helper to pop the head from the 2D array of account pending entries for a strategy.
     */
    function _popHeadAccountPendingEntries(dt.AccountInfo memory _accountInfo, uint32 stId) private pure {
        if (_accountInfo.pending.length <= uint256(stId)) {
            return;
        }

        uint256 n = _accountInfo.pending[stId].length;
        if (n == 0) {
            return;
        }

        dt.PendingAccountInfo[] memory arr = new dt.PendingAccountInfo[](n - 1); // zero is ok for empty array
        for (uint256 i = 1; i < n; i++) {
            arr[i - 1] = _accountInfo.pending[stId][i];
        }
        _accountInfo.pending[stId] = arr;
    }

    /**
     * Helper to pop the head from the strategy pending entries.
     */
    function _popHeadStrategyPendingEntries(dt.StrategyInfo memory _strategyInfo) private pure {
        uint256 n = _strategyInfo.pending.length;
        if (n == 0) {
            return;
        }

        dt.PendingStrategyInfo[] memory arr = new dt.PendingStrategyInfo[](n - 1); // zero is ok for empty array
        for (uint256 i = 1; i < n; i++) {
            arr[i - 1] = _strategyInfo.pending[i];
        }
        _strategyInfo.pending = arr;
    }
}

// SPDX-License-Identifier: MIT

// 2nd part of the transition applier due to contract size restrictions

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/* Internal Imports */
import {DataTypes as dt} from "./libraries/DataTypes.sol";
import {Transitions as tn} from "./libraries/Transitions.sol";
import "./libraries/ErrMsg.sol";

contract TransitionApplier2 {
    uint256 public constant STAKING_SCALE_FACTOR = 1e12;

    /**********************
     * External Functions *
     **********************/

    /**
     * @notice Apply an AggregateOrdersTransition.
     *
     * @param _transition The disputed transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @return new strategy info after applying the disputed transition
     */
    function applyAggregateOrdersTransition(
        dt.AggregateOrdersTransition memory _transition,
        dt.StrategyInfo memory _strategyInfo
    ) public pure returns (dt.StrategyInfo memory) {
        uint256 npend = _strategyInfo.pending.length;
        require(npend > 0, ErrMsg.REQ_NO_PEND);
        dt.PendingStrategyInfo memory psi = _strategyInfo.pending[npend - 1];
        require(_transition.buyAmount == psi.buyAmount, ErrMsg.REQ_BAD_AMOUNT);
        require(_transition.sellShares == psi.sellShares, ErrMsg.REQ_BAD_SHARES);

        uint256 minSharesFromBuy = (_transition.buyAmount * 1e18) / psi.maxSharePriceForBuy;
        uint256 minAmountFromSell = (_transition.sellShares * psi.minSharePriceForSell) / 1e18;
        require(_transition.minSharesFromBuy == minSharesFromBuy, ErrMsg.REQ_BAD_SHARES);
        require(_transition.minAmountFromSell == minAmountFromSell, ErrMsg.REQ_BAD_AMOUNT);

        _strategyInfo.nextAggregateId++;

        return _strategyInfo;
    }

    /**
     * @notice Apply a ExecutionResultTransition.
     *
     * @param _transition The disputed transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new strategy info after applying the disputed transition
     */
    function applyExecutionResultTransition(
        dt.ExecutionResultTransition memory _transition,
        dt.StrategyInfo memory _strategyInfo,
        dt.GlobalInfo memory _globalInfo
    ) public pure returns (dt.StrategyInfo memory, dt.GlobalInfo memory) {
        uint256 idx;
        bool found = false;
        for (uint256 i = 0; i < _strategyInfo.pending.length; i++) {
            if (_strategyInfo.pending[i].aggregateId == _transition.aggregateId) {
                idx = i;
                found = true;
                break;
            }
        }
        require(found, ErrMsg.REQ_BAD_AGGR);

        if (_transition.success) {
            _strategyInfo.pending[idx].sharesFromBuy = _transition.sharesFromBuy;
            _strategyInfo.pending[idx].amountFromSell = _transition.amountFromSell;
        }
        _strategyInfo.pending[idx].executionSucceed = _transition.success;
        _strategyInfo.pending[idx].unsettledBuyAmount = _strategyInfo.pending[idx].buyAmount;
        _strategyInfo.pending[idx].unsettledSellShares = _strategyInfo.pending[idx].sellShares;
        _strategyInfo.lastExecAggregateId = _transition.aggregateId;

        // Piggy-back the update to the global epoch
        _globalInfo.currEpoch = _transition.currEpoch;

        return (_strategyInfo, _globalInfo);
    }

    /**
     * @notice Apply a WithdrawProtocolFeeTransition.
     *
     * @param _transition The disputed transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new global info after applying the disputed transition
     */
    function applyWithdrawProtocolFeeTransition(
        dt.WithdrawProtocolFeeTransition memory _transition,
        dt.GlobalInfo memory _globalInfo
    ) public pure returns (dt.GlobalInfo memory) {
        _globalInfo.protoFees[_transition.assetId] -= _transition.amount;
        return _globalInfo;
    }

    /**
     * @notice Apply a TransferOperatorFeeTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account info and global info after applying the disputed transition
     */
    function applyTransferOperatorFeeTransition(
        dt.TransferOperatorFeeTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.GlobalInfo memory _globalInfo
    ) external pure returns (dt.AccountInfo memory, dt.GlobalInfo memory) {
        require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        require(_accountInfo.account != address(0), ErrMsg.REQ_BAD_ACCT);

        uint32 assetFeeLen = uint32(_globalInfo.opFees.assets.length);
        if (assetFeeLen > 1) {
            tn.adjustAccountIdleAssetEntries(_accountInfo, assetFeeLen - 1);
            for (uint256 i = 1; i < assetFeeLen; i++) {
                _accountInfo.idleAssets[i] += _globalInfo.opFees.assets[i];
                _globalInfo.opFees.assets[i] = 0;
            }
        }

        uint32 shareFeeLen = uint32(_globalInfo.opFees.shares.length);
        if (shareFeeLen > 1) {
            tn.adjustAccountShareEntries(_accountInfo, shareFeeLen - 1);
            for (uint256 i = 1; i < shareFeeLen; i++) {
                _accountInfo.shares[i] += _globalInfo.opFees.shares[i];
                _globalInfo.opFees.shares[i] = 0;
            }
        }

        return (_accountInfo, _globalInfo);
    }

    /**
     * @notice Apply a StakeTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _stakingPoolInfo The involved staking pool from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account, staking pool and global info after applying the disputed transition
     */
    function applyStakeTransition(
        dt.StakeTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.StakingPoolInfo memory _stakingPoolInfo,
        dt.GlobalInfo memory _globalInfo
    )
        external
        pure
        returns (
            dt.AccountInfo memory,
            dt.StakingPoolInfo memory,
            dt.GlobalInfo memory
        )
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(
                        abi.encodePacked(
                            _transition.transitionType,
                            _transition.poolId,
                            _transition.shares,
                            _transition.fee,
                            _transition.timestamp
                        )
                    )
                ),
                _transition.v,
                _transition.r,
                _transition.s
            ) == _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );

        require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        require(_stakingPoolInfo.strategyId > 0, ErrMsg.REQ_BAD_SP);
        _accountInfo.timestamp = _transition.timestamp;

        uint32 poolId = _transition.poolId;
        uint256 feeInShares;
        (bool isCelr, uint256 fee) = tn.getFeeInfo(_transition.fee);
        if (isCelr) {
            _accountInfo.idleAssets[1] -= fee;
            tn.updateOpFee(_globalInfo, true, 1, fee);
        } else {
            feeInShares = fee;
            tn.updateOpFee(_globalInfo, false, _stakingPoolInfo.strategyId, fee);
        }
        uint256 addedShares = _transition.shares - feeInShares;

        _updatePoolStates(_stakingPoolInfo, _globalInfo);

        if (addedShares > 0) {
            _adjustAccountStakedShareAndStakeEntries(_accountInfo, poolId);
            uint256 addedStake = _getAdjustedStake(
                _accountInfo.stakedShares[poolId] + addedShares,
                _stakingPoolInfo.stakeAdjustmentFactor
            ) - _accountInfo.stakes[poolId];
            _accountInfo.stakedShares[poolId] += addedShares;
            _accountInfo.stakes[poolId] += addedStake;
            _stakingPoolInfo.totalShares += addedShares;
            _stakingPoolInfo.totalStakes += addedStake;

            for (uint32 rewardTokenId = 0; rewardTokenId < _stakingPoolInfo.rewardPerEpoch.length; rewardTokenId++) {
                _adjustAccountRewardDebtEntries(_accountInfo, poolId, rewardTokenId);
                _accountInfo.rewardDebts[poolId][rewardTokenId] +=
                    (addedStake * _stakingPoolInfo.accumulatedRewardPerUnit[rewardTokenId]) /
                    STAKING_SCALE_FACTOR;
            }
        }
        tn.adjustAccountShareEntries(_accountInfo, _stakingPoolInfo.strategyId);
        _accountInfo.shares[_stakingPoolInfo.strategyId] -= _transition.shares;

        return (_accountInfo, _stakingPoolInfo, _globalInfo);
    }

    /**
     * @notice Apply an UnstakeTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _stakingPoolInfo The involved staking pool from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account, staking pool and global info after applying the disputed transition
     */
    function applyUnstakeTransition(
        dt.UnstakeTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.StakingPoolInfo memory _stakingPoolInfo,
        dt.GlobalInfo memory _globalInfo
    )
        external
        pure
        returns (
            dt.AccountInfo memory,
            dt.StakingPoolInfo memory,
            dt.GlobalInfo memory
        )
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(
                        abi.encodePacked(
                            _transition.transitionType,
                            _transition.poolId,
                            _transition.shares,
                            _transition.fee,
                            _transition.timestamp
                        )
                    )
                ),
                _transition.v,
                _transition.r,
                _transition.s
            ) == _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );

        require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        require(_stakingPoolInfo.strategyId > 0, ErrMsg.REQ_BAD_SP);
        _accountInfo.timestamp = _transition.timestamp;

        uint32 poolId = _transition.poolId;
        uint256 feeInShares;
        (bool isCelr, uint256 fee) = tn.getFeeInfo(_transition.fee);
        if (isCelr) {
            _accountInfo.idleAssets[1] -= fee;
            tn.updateOpFee(_globalInfo, true, 1, fee);
        } else {
            feeInShares = fee;
            tn.updateOpFee(_globalInfo, false, _stakingPoolInfo.strategyId, fee);
        }
        uint256 removedShares = _transition.shares;

        _updatePoolStates(_stakingPoolInfo, _globalInfo);

        if (removedShares > 0) {
            _adjustAccountStakedShareAndStakeEntries(_accountInfo, poolId);
            uint256 removedStake = _accountInfo.stakes[poolId] -
                _getAdjustedStake(
                    _accountInfo.stakedShares[poolId] - removedShares,
                    _stakingPoolInfo.stakeAdjustmentFactor
                );
            _accountInfo.stakedShares[poolId] -= removedShares;
            _accountInfo.stakes[poolId] -= removedStake;
            _stakingPoolInfo.totalShares -= removedShares;
            _stakingPoolInfo.totalStakes -= removedStake;

            for (uint32 rewardTokenId = 0; rewardTokenId < _stakingPoolInfo.rewardPerEpoch.length; rewardTokenId++) {
                _adjustAccountRewardDebtEntries(_accountInfo, poolId, rewardTokenId);
                _accountInfo.rewardDebts[poolId][rewardTokenId] -=
                    (removedStake * _stakingPoolInfo.accumulatedRewardPerUnit[rewardTokenId]) /
                    STAKING_SCALE_FACTOR;
            }
        }
        // Harvest
        for (uint32 rewardTokenId = 0; rewardTokenId < _stakingPoolInfo.rewardPerEpoch.length; rewardTokenId++) {
            uint256 accumulatedReward = (_accountInfo.stakes[poolId] *
                _stakingPoolInfo.accumulatedRewardPerUnit[rewardTokenId]) / STAKING_SCALE_FACTOR;
            uint256 pendingReward = (accumulatedReward - _accountInfo.rewardDebts[poolId][rewardTokenId]);
            _accountInfo.rewardDebts[poolId][rewardTokenId] = accumulatedReward;
            uint32 assetId = _stakingPoolInfo.rewardAssetIds[rewardTokenId];
            _globalInfo.rewards = tn.adjustUint256Array(_globalInfo.rewards, assetId);
            // Cap to available reward
            if (pendingReward > _globalInfo.rewards[assetId]) {
                pendingReward = _globalInfo.rewards[assetId];
            }
            _accountInfo.idleAssets[assetId] += pendingReward;
            _globalInfo.rewards[assetId] -= pendingReward;
        }
        tn.adjustAccountShareEntries(_accountInfo, _stakingPoolInfo.strategyId);
        _accountInfo.shares[_stakingPoolInfo.strategyId] += _transition.shares - feeInShares;

        return (_accountInfo, _stakingPoolInfo, _globalInfo);
    }

    /**
     * @notice Apply an AddPoolTransition.
     *
     * @param _transition The disputed transition.
     * @param _stakingPoolInfo The involved staking pool from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new staking pool info after applying the disputed transition
     */
    function applyAddPoolTransition(
        dt.AddPoolTransition memory _transition,
        dt.StakingPoolInfo memory _stakingPoolInfo,
        dt.GlobalInfo memory _globalInfo
    ) external pure returns (dt.StakingPoolInfo memory) {
        require(_transition.rewardAssetIds.length == _transition.rewardPerEpoch.length, ErrMsg.REQ_BAD_LEN);
        require(_stakingPoolInfo.strategyId == 0, ErrMsg.REQ_BAD_SP);
        require(_transition.startEpoch >= _globalInfo.currEpoch, ErrMsg.REQ_BAD_EPOCH);

        _stakingPoolInfo.lastRewardEpoch = _transition.startEpoch;
        _stakingPoolInfo.stakeAdjustmentFactor = _transition.stakeAdjustmentFactor;
        _stakingPoolInfo.strategyId = _transition.strategyId;
        _stakingPoolInfo.rewardAssetIds = _transition.rewardAssetIds;
        _stakingPoolInfo.accumulatedRewardPerUnit = tn.adjustUint256Array(
            _stakingPoolInfo.accumulatedRewardPerUnit,
            uint32(_transition.rewardAssetIds.length)
        );
        _stakingPoolInfo.rewardPerEpoch = _transition.rewardPerEpoch;
        return _stakingPoolInfo;
    }

    /**
     * @notice Apply an UpdatePoolTransition.
     *
     * @param _transition The disputed transition.
     * @param _stakingPoolInfo The involved staking pool from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new staking pool info after applying the disputed transition
     */
    function applyUpdatePoolTransition(
        dt.UpdatePoolTransition memory _transition,
        dt.StakingPoolInfo memory _stakingPoolInfo,
        dt.GlobalInfo memory _globalInfo
    ) external pure returns (dt.StakingPoolInfo memory) {
        require(_transition.rewardPerEpoch.length == _stakingPoolInfo.rewardPerEpoch.length, ErrMsg.REQ_BAD_LEN);
        require(_stakingPoolInfo.strategyId > 0, ErrMsg.REQ_BAD_SP);

        _updatePoolStates(_stakingPoolInfo, _globalInfo);

        _stakingPoolInfo.rewardPerEpoch = _transition.rewardPerEpoch;
        return _stakingPoolInfo;
    }

    /**
     * @notice Apply a DepositRewardTransition.
     *
     * @param _transition The disputed transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new global info after applying the disputed transition
     */
    function applyDepositRewardTransition(
        dt.DepositRewardTransition memory _transition,
        dt.GlobalInfo memory _globalInfo
    ) public pure returns (dt.GlobalInfo memory) {
        _globalInfo.rewards = tn.adjustUint256Array(_globalInfo.rewards, _transition.assetId);
        _globalInfo.rewards[_transition.assetId] += _transition.amount;
        return _globalInfo;
    }

    /*********************
     * Private Functions *
     *********************/

    function _updatePoolStates(dt.StakingPoolInfo memory _stakingPoolInfo, dt.GlobalInfo memory _globalInfo)
        private
        pure
    {
        if (_globalInfo.currEpoch > _stakingPoolInfo.lastRewardEpoch) {
            uint256 totalStakes = _stakingPoolInfo.totalStakes;
            if (totalStakes > 0) {
                uint64 numEpochs = _globalInfo.currEpoch - _stakingPoolInfo.lastRewardEpoch;
                for (
                    uint32 rewardTokenId = 0;
                    rewardTokenId < _stakingPoolInfo.rewardPerEpoch.length;
                    rewardTokenId++
                ) {
                    uint256 pendingReward = numEpochs * _stakingPoolInfo.rewardPerEpoch[rewardTokenId];
                    _stakingPoolInfo.accumulatedRewardPerUnit[rewardTokenId] += ((pendingReward *
                        STAKING_SCALE_FACTOR) / totalStakes);
                }
            }
            _stakingPoolInfo.lastRewardEpoch = _globalInfo.currEpoch;
        }
    }

    /**
     * Helper to expand the account array of staked shares and stakes if needed.
     */
    function _adjustAccountStakedShareAndStakeEntries(dt.AccountInfo memory _accountInfo, uint32 poolId) private pure {
        uint32 n = uint32(_accountInfo.stakedShares.length);
        if (n <= poolId) {
            uint256[] memory arr = new uint256[](poolId + 1);
            for (uint32 i = 0; i < n; i++) {
                arr[i] = _accountInfo.stakedShares[i];
            }
            for (uint32 i = n; i <= poolId; i++) {
                arr[i] = 0;
            }
            _accountInfo.stakedShares = arr;
        }
        n = uint32(_accountInfo.stakes.length);
        if (n <= poolId) {
            uint256[] memory arr = new uint256[](poolId + 1);
            for (uint32 i = 0; i < n; i++) {
                arr[i] = _accountInfo.stakes[i];
            }
            for (uint32 i = n; i <= poolId; i++) {
                arr[i] = 0;
            }
            _accountInfo.stakes = arr;
        }
    }

    /**
     * Helper to expand the 2D array of account reward debt entries per pool and reward token IDs.
     */
    function _adjustAccountRewardDebtEntries(
        dt.AccountInfo memory _accountInfo,
        uint32 poolId,
        uint32 rewardTokenId
    ) private pure {
        uint32 n = uint32(_accountInfo.rewardDebts.length);
        if (n <= poolId) {
            uint256[][] memory rewardDebts = new uint256[][](poolId + 1);
            for (uint32 i = 0; i < n; i++) {
                rewardDebts[i] = _accountInfo.rewardDebts[i];
            }
            for (uint32 i = n; i < poolId; i++) {
                rewardDebts[i] = new uint256[](0);
            }
            rewardDebts[poolId] = new uint256[](rewardTokenId + 1);
            _accountInfo.rewardDebts = rewardDebts;
        }
        uint32 nRewardTokens = uint32(_accountInfo.rewardDebts[poolId].length);
        if (nRewardTokens <= rewardTokenId) {
            uint256[] memory debts = new uint256[](rewardTokenId + 1);
            for (uint32 i = 0; i < nRewardTokens; i++) {
                debts[i] = _accountInfo.rewardDebts[poolId][i];
            }
            for (uint32 i = nRewardTokens; i <= rewardTokenId; i++) {
                debts[i] = 0;
            }
            _accountInfo.rewardDebts[poolId] = debts;
        }
    }

    /**
     * @notice Calculates the adjusted stake from staked shares.
     * @param _stakedShares The staked shares
     * @param _adjustmentFactor The adjustment factor, a value from (0, 1) * STAKING_SCALE_FACTOR
     */
    function _getAdjustedStake(uint256 _stakedShares, uint256 _adjustmentFactor) private pure returns (uint256) {
        return
            ((STAKING_SCALE_FACTOR - _adjustmentFactor) *
                _stakedShares +
                _sqrt(STAKING_SCALE_FACTOR * _adjustmentFactor * _stakedShares)) / STAKING_SCALE_FACTOR;
    }

    /**
     * @notice Implements square root with Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method).
     * @param _y The input
     */
    function _sqrt(uint256 _y) private pure returns (uint256) {
        uint256 z;
        if (_y > 3) {
            z = _y;
            uint256 x = _y / 2 + 1;
            while (x < z) {
                z = x;
                x = (_y / x + x) / 2;
            }
        } else if (_y != 0) {
            z = 1;
        }
        return z;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/* Internal Imports */
import {DataTypes as dt} from "./libraries/DataTypes.sol";
import {Transitions as tn} from "./libraries/Transitions.sol";
import "./libraries/ErrMsg.sol";
import "./TransitionApplier1.sol";
import "./TransitionApplier2.sol";
import "./Registry.sol";

contract TransitionEvaluator {
    TransitionApplier1 public immutable transitionApplier1;
    TransitionApplier2 public immutable transitionApplier2;

    // Transition evaluation is split across 3 contracts, this one is the main entry point.
    // In turn, it needs to access the other two contracts to evaluate the other transitions.
    constructor(TransitionApplier1 _transitionApplier1, TransitionApplier2 _transitionApplier2) {
        transitionApplier1 = _transitionApplier1;
        transitionApplier2 = _transitionApplier2;
    }

    /**********************
     * External Functions *
     **********************/

    /**
     * @notice Evaluate a transition.
     * @dev Note: most transitions involve one account; the transfer transitions involve two (src, dest).
     *
     * @param _transition The disputed transition.
     * @param _infos The involved infos at the start of the disputed transition.
     * @param _registry The address of the Registry contract.
     * @return hashes of the accounts (src and dest), strategy, staking pool and global info after applying the disputed transition.
     */
    function evaluateTransition(
        bytes calldata _transition,
        dt.EvaluateInfos calldata _infos,
        Registry _registry
    ) external view returns (bytes32[5] memory) {
        // Extract the transition type
        uint8 transitionType = tn.extractTransitionType(_transition);
        bytes32[5] memory outputs;
        outputs[4] = getGlobalInfoHash(_infos.globalInfo);
        dt.EvaluateInfos memory updatedInfos;
        updatedInfos.accountInfos = new dt.AccountInfo[](2);

        // Apply the transition and record the resulting storage slots
        if (transitionType == tn.TN_TYPE_DEPOSIT) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.DepositTransition memory deposit = tn.decodePackedDepositTransition(_transition);
            updatedInfos.accountInfos[0] = transitionApplier1.applyDepositTransition(deposit, _infos.accountInfos[0]);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
        } else if (transitionType == tn.TN_TYPE_WITHDRAW) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.WithdrawTransition memory withdraw = tn.decodePackedWithdrawTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.globalInfo) = transitionApplier1.applyWithdrawTransition(
                withdraw,
                _infos.accountInfos[0],
                _infos.globalInfo
            );
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_BUY) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.BuyTransition memory buy = tn.decodePackedBuyTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.strategyInfo) = transitionApplier1.applyBuyTransition(
                buy,
                _infos.accountInfos[0],
                _infos.strategyInfo,
                _registry
            );
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[2] = getStrategyInfoHash(updatedInfos.strategyInfo);
        } else if (transitionType == tn.TN_TYPE_SELL) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.SellTransition memory sell = tn.decodePackedSellTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.strategyInfo) = transitionApplier1.applySellTransition(
                sell,
                _infos.accountInfos[0],
                _infos.strategyInfo
            );
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[2] = getStrategyInfoHash(updatedInfos.strategyInfo);
        } else if (transitionType == tn.TN_TYPE_XFER_ASSET) {
            require(_infos.accountInfos.length == 2, ErrMsg.REQ_TWO_ACCT);
            dt.TransferAssetTransition memory xfer = tn.decodePackedTransferAssetTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.accountInfos[1], updatedInfos.globalInfo) = transitionApplier1
                .applyAssetTransferTransition(xfer, _infos.accountInfos[0], _infos.accountInfos[1], _infos.globalInfo);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[1] = getAccountInfoHash(updatedInfos.accountInfos[1]);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_XFER_SHARE) {
            require(_infos.accountInfos.length == 2, ErrMsg.REQ_TWO_ACCT);
            dt.TransferShareTransition memory xfer = tn.decodePackedTransferShareTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.accountInfos[1], updatedInfos.globalInfo) = transitionApplier1
                .applyShareTransferTransition(xfer, _infos.accountInfos[0], _infos.accountInfos[1], _infos.globalInfo);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[1] = getAccountInfoHash(updatedInfos.accountInfos[1]);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_AGGREGATE_ORDER) {
            dt.AggregateOrdersTransition memory aggr = tn.decodePackedAggregateOrdersTransition(_transition);
            updatedInfos.strategyInfo = transitionApplier2.applyAggregateOrdersTransition(aggr, _infos.strategyInfo);
            outputs[2] = getStrategyInfoHash(updatedInfos.strategyInfo);
        } else if (transitionType == tn.TN_TYPE_EXEC_RESULT) {
            dt.ExecutionResultTransition memory res = tn.decodePackedExecutionResultTransition(_transition);
            (updatedInfos.strategyInfo, updatedInfos.globalInfo) = transitionApplier2.applyExecutionResultTransition(
                res,
                _infos.strategyInfo,
                _infos.globalInfo
            );
            outputs[2] = getStrategyInfoHash(updatedInfos.strategyInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_SETTLE) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.SettlementTransition memory settle = tn.decodePackedSettlementTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.strategyInfo, updatedInfos.globalInfo) = transitionApplier1
                .applySettlementTransition(settle, _infos.accountInfos[0], _infos.strategyInfo, _infos.globalInfo);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[2] = getStrategyInfoHash(updatedInfos.strategyInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_STAKE) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.StakeTransition memory stake = tn.decodePackedStakeTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.stakingPoolInfo, updatedInfos.globalInfo) = transitionApplier2
                .applyStakeTransition(stake, _infos.accountInfos[0], _infos.stakingPoolInfo, _infos.globalInfo);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[3] = getStakingPoolInfoHash(updatedInfos.stakingPoolInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_UNSTAKE) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.UnstakeTransition memory unstake = tn.decodePackedUnstakeTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.stakingPoolInfo, updatedInfos.globalInfo) = transitionApplier2
                .applyUnstakeTransition(unstake, _infos.accountInfos[0], _infos.stakingPoolInfo, _infos.globalInfo);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[3] = getStakingPoolInfoHash(updatedInfos.stakingPoolInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_ADD_POOL) {
            dt.AddPoolTransition memory addPool = tn.decodeAddPoolTransition(_transition);
            updatedInfos.stakingPoolInfo = transitionApplier2.applyAddPoolTransition(
                addPool,
                _infos.stakingPoolInfo,
                _infos.globalInfo
            );
            outputs[3] = getStakingPoolInfoHash(updatedInfos.stakingPoolInfo);
        } else if (transitionType == tn.TN_TYPE_UPDATE_POOL) {
            dt.UpdatePoolTransition memory updatePool = tn.decodeUpdatePoolTransition(_transition);
            updatedInfos.stakingPoolInfo = transitionApplier2.applyUpdatePoolTransition(
                updatePool,
                _infos.stakingPoolInfo,
                _infos.globalInfo
            );
            outputs[3] = getStakingPoolInfoHash(updatedInfos.stakingPoolInfo);
        } else if (transitionType == tn.TN_TYPE_DEPOSIT_REWARD) {
            dt.DepositRewardTransition memory dr = tn.decodeDepositRewardTransition(_transition);
            updatedInfos.globalInfo = transitionApplier2.applyDepositRewardTransition(dr, _infos.globalInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_WITHDRAW_PROTO_FEE) {
            dt.WithdrawProtocolFeeTransition memory wpf = tn.decodeWithdrawProtocolFeeTransition(_transition);
            updatedInfos.globalInfo = transitionApplier2.applyWithdrawProtocolFeeTransition(wpf, _infos.globalInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_XFER_OP_FEE) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.TransferOperatorFeeTransition memory tof = tn.decodeTransferOperatorFeeTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.globalInfo) = transitionApplier2
                .applyTransferOperatorFeeTransition(tof, _infos.accountInfos[0], _infos.globalInfo);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else {
            revert("Transition type not recognized");
        }
        return outputs;
    }

    /**
     * @notice Return the (stateRoot, accountId, accountIdDest, strategyId, stakingPoolId) for this transition.
     * @dev Note: most transitions involve one account; the transfer transitions involve a 2nd account (dest).
     */
    function getTransitionStateRootAndAccessIds(bytes calldata _rawTransition)
        external
        pure
        returns (
            bytes32,
            uint32,
            uint32,
            uint32,
            uint32
        )
    {
        // Initialize memory rawTransition
        bytes memory rawTransition = _rawTransition;
        // Initialize stateRoot and account and strategy IDs.
        bytes32 stateRoot;
        uint32 accountId;
        uint32 accountIdDest;
        uint32 strategyId;
        uint32 stakingPoolId;
        uint8 transitionType = tn.extractTransitionType(rawTransition);
        if (transitionType == tn.TN_TYPE_DEPOSIT) {
            dt.DepositTransition memory transition = tn.decodePackedDepositTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
        } else if (transitionType == tn.TN_TYPE_WITHDRAW) {
            dt.WithdrawTransition memory transition = tn.decodePackedWithdrawTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
        } else if (transitionType == tn.TN_TYPE_BUY) {
            dt.BuyTransition memory transition = tn.decodePackedBuyTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
            strategyId = transition.strategyId;
        } else if (transitionType == tn.TN_TYPE_SELL) {
            dt.SellTransition memory transition = tn.decodePackedSellTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
            strategyId = transition.strategyId;
        } else if (transitionType == tn.TN_TYPE_XFER_ASSET) {
            dt.TransferAssetTransition memory transition = tn.decodePackedTransferAssetTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.fromAccountId;
            accountIdDest = transition.toAccountId;
        } else if (transitionType == tn.TN_TYPE_XFER_SHARE) {
            dt.TransferShareTransition memory transition = tn.decodePackedTransferShareTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.fromAccountId;
            accountIdDest = transition.toAccountId;
        } else if (transitionType == tn.TN_TYPE_AGGREGATE_ORDER) {
            dt.AggregateOrdersTransition memory transition = tn.decodePackedAggregateOrdersTransition(rawTransition);
            stateRoot = transition.stateRoot;
            strategyId = transition.strategyId;
        } else if (transitionType == tn.TN_TYPE_EXEC_RESULT) {
            dt.ExecutionResultTransition memory transition = tn.decodePackedExecutionResultTransition(rawTransition);
            stateRoot = transition.stateRoot;
            strategyId = transition.strategyId;
        } else if (transitionType == tn.TN_TYPE_SETTLE) {
            dt.SettlementTransition memory transition = tn.decodePackedSettlementTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
            strategyId = transition.strategyId;
        } else if (transitionType == tn.TN_TYPE_STAKE) {
            dt.StakeTransition memory transition = tn.decodePackedStakeTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
            stakingPoolId = transition.poolId;
        } else if (transitionType == tn.TN_TYPE_UNSTAKE) {
            dt.UnstakeTransition memory transition = tn.decodePackedUnstakeTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
            stakingPoolId = transition.poolId;
        } else if (transitionType == tn.TN_TYPE_ADD_POOL) {
            dt.AddPoolTransition memory transition = tn.decodeAddPoolTransition(rawTransition);
            stateRoot = transition.stateRoot;
            stakingPoolId = transition.poolId;
        } else if (transitionType == tn.TN_TYPE_UPDATE_POOL) {
            dt.UpdatePoolTransition memory transition = tn.decodeUpdatePoolTransition(rawTransition);
            stateRoot = transition.stateRoot;
            stakingPoolId = transition.poolId;
        } else if (transitionType == tn.TN_TYPE_DEPOSIT_REWARD) {
            dt.DepositRewardTransition memory transition = tn.decodeDepositRewardTransition(rawTransition);
            stateRoot = transition.stateRoot;
        } else if (transitionType == tn.TN_TYPE_WITHDRAW_PROTO_FEE) {
            dt.WithdrawProtocolFeeTransition memory transition = tn.decodeWithdrawProtocolFeeTransition(rawTransition);
            stateRoot = transition.stateRoot;
        } else if (transitionType == tn.TN_TYPE_XFER_OP_FEE) {
            dt.TransferOperatorFeeTransition memory transition = tn.decodeTransferOperatorFeeTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
        } else if (transitionType == tn.TN_TYPE_INIT) {
            dt.InitTransition memory transition = tn.decodeInitTransition(rawTransition);
            stateRoot = transition.stateRoot;
        } else {
            revert("Transition type not recognized");
        }
        return (stateRoot, accountId, accountIdDest, strategyId, stakingPoolId);
    }

    /**
     * @notice Get the hash of the AccountInfo.
     * @param _accountInfo Account info
     */
    function getAccountInfoHash(dt.AccountInfo memory _accountInfo) public pure returns (bytes32) {
        // If it's an empty struct, map it to 32 bytes of zeros (empty value)
        if (
            _accountInfo.account == address(0) &&
            _accountInfo.accountId == 0 &&
            _accountInfo.idleAssets.length == 0 &&
            _accountInfo.shares.length == 0 &&
            _accountInfo.pending.length == 0 &&
            _accountInfo.stakedShares.length == 0 &&
            _accountInfo.stakes.length == 0 &&
            _accountInfo.rewardDebts.length == 0 &&
            _accountInfo.timestamp == 0
        ) {
            return keccak256(abi.encodePacked(uint256(0)));
        }

        return keccak256(abi.encode(_accountInfo));
    }

    /**
     * @notice Get the hash of the StrategyInfo.
     * @param _strategyInfo Strategy info
     */
    function getStrategyInfoHash(dt.StrategyInfo memory _strategyInfo) public pure returns (bytes32) {
        // If it's an empty struct, map it to 32 bytes of zeros (empty value)
        if (
            _strategyInfo.assetId == 0 &&
            _strategyInfo.assetBalance == 0 &&
            _strategyInfo.shareSupply == 0 &&
            _strategyInfo.nextAggregateId == 0 &&
            _strategyInfo.lastExecAggregateId == 0 &&
            _strategyInfo.pending.length == 0
        ) {
            return keccak256(abi.encodePacked(uint256(0)));
        }

        return keccak256(abi.encode(_strategyInfo));
    }

    /**
     * @notice Get the hash of the StakingPoolInfo.
     * @param _stakingPoolInfo Staking pool info
     */
    function getStakingPoolInfoHash(dt.StakingPoolInfo memory _stakingPoolInfo) public pure returns (bytes32) {
        // If it's an empty struct, map it to 32 bytes of zeros (empty value)
        if (
            _stakingPoolInfo.strategyId == 0 &&
            _stakingPoolInfo.rewardAssetIds.length == 0 &&
            _stakingPoolInfo.rewardPerEpoch.length == 0 &&
            _stakingPoolInfo.totalShares == 0 &&
            _stakingPoolInfo.totalStakes == 0 &&
            _stakingPoolInfo.accumulatedRewardPerUnit.length == 0 &&
            _stakingPoolInfo.lastRewardEpoch == 0 &&
            _stakingPoolInfo.stakeAdjustmentFactor == 0
        ) {
            return keccak256(abi.encodePacked(uint256(0)));
        }

        return keccak256(abi.encode(_stakingPoolInfo));
    }

    /**
     * @notice Get the hash of the GlobalInfo.
     * @param _globalInfo Global info
     */
    function getGlobalInfoHash(dt.GlobalInfo memory _globalInfo) public pure returns (bytes32) {
        return keccak256(abi.encode(_globalInfo));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library DataTypes {
    struct Block {
        bytes32 rootHash;
        bytes32 intentHash; // hash of L2-to-L1 aggregate-orders transitions
        uint32 intentExecCount; // count of intents executed so far (MAX_UINT32 == all done)
        uint32 blockSize; // number of transitions in the block
        uint64 blockTime; // blockNum when this rollup block is committed
    }

    struct InitTransition {
        uint8 transitionType;
        bytes32 stateRoot;
    }

    // decoded from calldata submitted as PackedDepositTransition
    struct DepositTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        address account;
        uint32 accountId;
        uint32 assetId;
        uint256 amount;
    }

    // decoded from calldata submitted as PackedWithdrawTransition
    struct WithdrawTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        address account; // target address for "pending withdraw" handling
        uint32 accountId;
        uint32 assetId;
        uint256 amount;
        uint128 fee;
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedBuySellTransition
    struct BuyTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 strategyId;
        uint256 amount;
        uint128 maxSharePrice;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedBuySellTransition
    struct SellTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 strategyId;
        uint256 shares;
        uint128 minSharePrice;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedTransferTransition
    struct TransferAssetTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 fromAccountId;
        uint32 toAccountId;
        address toAccount;
        uint32 assetId;
        uint256 amount;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedTransferTransition
    struct TransferShareTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 fromAccountId;
        uint32 toAccountId;
        address toAccount;
        uint32 strategyId;
        uint256 shares;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedSettlementTransition
    struct SettlementTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        uint64 aggregateId;
        uint32 accountId;
        uint128 celrRefund; // fee refund in celr
        uint128 assetRefund; // fee refund in asset
    }

    // decoded from calldata submitted as PackedAggregateOrdersTransition
    struct AggregateOrdersTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        uint256 buyAmount;
        uint256 sellShares;
        uint256 minSharesFromBuy;
        uint256 minAmountFromSell;
    }

    // decoded from calldata submitted as PackedExecutionResultTransition
    struct ExecutionResultTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        uint64 aggregateId;
        bool success;
        uint256 sharesFromBuy;
        uint256 amountFromSell;
        uint64 currEpoch;
    }

    // decoded from calldata submitted as PackedStakingTransition
    struct StakeTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 poolId;
        uint32 accountId;
        uint256 shares;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedStakingTransition
    struct UnstakeTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 poolId;
        uint256 shares;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    struct AddPoolTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 poolId;
        uint32 strategyId;
        uint32[] rewardAssetIds;
        uint256[] rewardPerEpoch;
        uint256 stakeAdjustmentFactor;
        uint64 startEpoch;
    }

    struct UpdatePoolTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 poolId;
        uint256[] rewardPerEpoch;
    }

    struct DepositRewardTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 assetId;
        uint256 amount;
    }

    struct WithdrawProtocolFeeTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 assetId;
        uint256 amount;
    }

    struct TransferOperatorFeeTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId; // destination account Id
    }

    struct OperatorFees {
        uint256[] assets; // assetId -> collected asset fees. CELR has assetId 1.
        uint256[] shares; // strategyId -> collected strategy share fees.
    }

    struct GlobalInfo {
        uint256[] protoFees; // assetId -> collected asset fees owned by contract owner (governance multi-sig account)
        OperatorFees opFees; // fee owned by operator
        uint64 currEpoch; // liquidity mining epoch
        uint256[] rewards; // assetId -> available reward amount
    }

    // Pending account actions (buy/sell) per account, strategy, aggregateId.
    // The array of PendingAccountInfo structs is sorted by ascending aggregateId, and holes are ok.
    struct PendingAccountInfo {
        uint64 aggregateId;
        uint256 buyAmount;
        uint256 sellShares;
        uint256 buyFees; // fees (in asset) for buy transitions
        uint256 sellFees; // fees (in asset) for sell transitions
        uint256 celrFees; // fees (in celr) for buy and sell transitions
    }

    struct AccountInfo {
        address account;
        uint32 accountId; // mapping only on L2 must be part of stateRoot
        uint256[] idleAssets; // indexed by assetId
        uint256[] shares; // indexed by strategyId
        PendingAccountInfo[][] pending; // indexed by [strategyId][i], i.e. array of pending records per strategy
        uint256[] stakedShares; // poolID -> share balance
        uint256[] stakes; // poolID -> Adjusted stake
        uint256[][] rewardDebts; // poolID -> rewardTokenID -> Reward debt
        uint64 timestamp; // Unix epoch (msec, UTC)
    }

    // Pending strategy actions per strategy, aggregateId.
    // The array of PendingStrategyInfo structs is sorted by ascending aggregateId, and holes are ok.
    struct PendingStrategyInfo {
        uint64 aggregateId;
        uint128 maxSharePriceForBuy; // decimal in 1e18
        uint128 minSharePriceForSell; // decimal in 1e18
        uint256 buyAmount;
        uint256 sellShares;
        uint256 sharesFromBuy;
        uint256 amountFromSell;
        uint256 unsettledBuyAmount;
        uint256 unsettledSellShares;
        bool executionSucceed;
    }

    struct StrategyInfo {
        uint32 assetId;
        uint256 assetBalance;
        uint256 shareSupply;
        uint64 nextAggregateId;
        uint64 lastExecAggregateId;
        PendingStrategyInfo[] pending; // array of pending records
    }

    struct StakingPoolInfo {
        uint32 strategyId;
        uint32[] rewardAssetIds; // reward asset index -> asset ID
        uint256[] rewardPerEpoch; // reward asset index -> reward per epoch, must be limited in length
        uint256 totalShares;
        uint256 totalStakes;
        uint256[] accumulatedRewardPerUnit; // reward asset index -> Accumulated reward per unit of stake, times 1e12 to avoid very small numbers
        uint64 lastRewardEpoch; // Last epoch that reward distribution occurs. Initially set by an AddPoolTransition
        uint256 stakeAdjustmentFactor; // A fraction to dilute whales. i.e. (0, 1) * 1e12
    }

    struct TransitionProof {
        bytes transition;
        uint256 blockId;
        uint32 index;
        bytes32[] siblings;
    }

    // Even when the disputed transition only affects an account without a strategy or only
    // affects a strategy without an account, both AccountProof and StrategyProof must be sent
    // to at least give the root hashes of the two separate Merkle trees (account and strategy).
    // Each transition stateRoot = hash(accountStateRoot, strategyStateRoot).
    struct AccountProof {
        bytes32 stateRoot; // for the account Merkle tree
        AccountInfo value;
        uint32 index;
        bytes32[] siblings;
    }

    struct StrategyProof {
        bytes32 stateRoot; // for the strategy Merkle tree
        StrategyInfo value;
        uint32 index;
        bytes32[] siblings;
    }

    struct StakingPoolProof {
        bytes32 stateRoot; // for the staking pool Merkle tree
        StakingPoolInfo value;
        uint32 index;
        bytes32[] siblings;
    }

    struct EvaluateInfos {
        AccountInfo[] accountInfos;
        StrategyInfo strategyInfo;
        StakingPoolInfo stakingPoolInfo;
        GlobalInfo globalInfo;
    }

    // ------------------ packed transitions submitted as calldata ------------------

    // calldata size: 4 x 32 bytes
    struct PackedDepositTransition {
        /* infoCode packing:
        96:127 [uint32 accountId]
        64:95  [uint32 assetId]
        8:63   [0]
        0:7    [uint8 tntype] */
        uint128 infoCode;
        bytes32 stateRoot;
        address account;
        uint256 amount;
    }

    // calldata size: 7 x 32 bytes
    struct PackedWithdrawTransition {
        /* infoCode packing:
        224:255 [uint32 accountId]
        192:223 [uint32 assetId]
        128:191 [uint64 timestamp]
        16:127  [0]
        8:15    [uint8 sig-v]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        address account;
        uint256 amtfee; // [128bit-amount]:[128bit-fee] uint128 is large enough
        bytes32 r;
        bytes32 s;
    }

    // calldata size: 6 x 32 bytes
    struct PackedBuySellTransition {
        /* infoCode packing:
        224:255 [uint32 accountId]
        192:223 [uint32 strategyId]
        128:191 [uint64 timestamp]
        16:127  [uint112 minSharePrice or maxSharePrice] // 112 bits are enough
        8:15    [uint8 sig-v]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        uint256 amtfee; // [128bit-share/amount]:[128bit-fee] uint128 is large enough
        bytes32 r;
        bytes32 s;
    }

    // calldata size: 6 x 32 bytes
    struct PackedTransferTransition {
        /* infoCode packing:
        224:255 [0]
        192:223 [uint32 assetId or strategyId]
        160:191 [uint32 fromAccountId]
        128:159 [uint32 toAccountId]
        64:127  [uint64 timestamp]
        16:63   [0]
        8:15    [uint8 sig-v]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        address toAccount;
        uint256 amtfee; // [128bit-share/amount]:[128bit-fee] uint128 is large enough
        bytes32 r;
        bytes32 s;
    }

    // calldata size: 2 x 32 bytes
    struct PackedSettlementTransition {
        /* infoCode packing:
        224:255 [uint32 accountId]
        192:223 [uint32 strategyId]
        160:191 [uint32 aggregateId] // uint32 is enough for per-strategy aggregateId
        104:159 [uint56 celrRefund] // celr refund in 9 decimal
        8:103   [uint96 assetRefund] // asseet refund
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
    }

    // calldata size: 6 x 32 bytes
    struct PackedAggregateOrdersTransition {
        /* infoCode packing:
        32:63  [uint32 strategyId]
        8:31   [0]
        0:7    [uint8 tntype] */
        uint64 infoCode;
        bytes32 stateRoot;
        uint256 buyAmount;
        uint256 sellShares;
        uint256 minSharesFromBuy;
        uint256 minAmountFromSell;
    }

    // calldata size: 4 x 32 bytes
    struct PackedExecutionResultTransition {
        /* infoCode packing:
        192:255 [0]
        128:191 [uint64 currEpoch]
        64:127  [uint64 aggregateId]
        32:63   [uint32 strategyId]
        9:31    [0]
        8:8     [bool success]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        uint256 sharesFromBuy;
        uint256 amountFromSell;
    }

    // calldata size: 6 x 32 bytes
    struct PackedStakingTransition {
        /* infoCode packing:
        192:255 [0]
        160:191 [uint32 poolId]
        128:159 [uint32 accountId]
        64:127  [uint64 timestamp]
        16:63   [0]
        8:15    [uint8 sig-v]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        uint256 sharefee; // [128bit-share]:[128bit-fee] uint128 is large enough
        bytes32 r;
        bytes32 s;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library ErrMsg {
    // err message for `require` checks
    string internal constant REQ_NOT_OPER = "caller not operator";
    string internal constant REQ_BAD_AMOUNT = "invalid amount";
    string internal constant REQ_NO_WITHDRAW = "withdraw failed";
    string internal constant REQ_BAD_BLOCKID = "invalid block ID";
    string internal constant REQ_BAD_CHALLENGE = "challenge period error";
    string internal constant REQ_BAD_HASH = "invalid data hash";
    string internal constant REQ_BAD_LEN = "invalid data length";
    string internal constant REQ_NO_DRAIN = "drain failed";
    string internal constant REQ_BAD_ASSET = "invalid asset";
    string internal constant REQ_BAD_ST = "invalid strategy";
    string internal constant REQ_BAD_SP = "invalid staking pool";
    string internal constant REQ_BAD_EPOCH = "invalid epoch";
    string internal constant REQ_OVER_LIMIT = "exceeds limit";
    string internal constant REQ_BAD_DEP_TN = "invalid deposit tn";
    string internal constant REQ_BAD_EXECRES_TN = "invalid execRes tn";
    string internal constant REQ_ONE_ACCT = "need 1 account";
    string internal constant REQ_TWO_ACCT = "need 2 accounts";
    string internal constant REQ_ACCT_NOT_EMPTY = "account not empty";
    string internal constant REQ_BAD_ACCT = "wrong account";
    string internal constant REQ_BAD_SIG = "invalid signature";
    string internal constant REQ_BAD_TS = "old timestamp";
    string internal constant REQ_NO_PEND = "no pending info";
    string internal constant REQ_BAD_SHARES = "wrong shares";
    string internal constant REQ_BAD_AGGR = "wrong aggregate ID";
    string internal constant REQ_ST_NOT_EMPTY = "strategy not empty";
    string internal constant REQ_NO_FRAUD = "no fraud found";
    string internal constant REQ_BAD_NTREE = "bad n-tree verify";
    string internal constant REQ_BAD_SROOT = "state roots not equal";
    string internal constant REQ_BAD_INDEX = "wrong proof index";
    string internal constant REQ_BAD_PREV_TN = "invalid prev tn";
    string internal constant REQ_TN_NOT_IN = "tn not in block";
    string internal constant REQ_TN_NOT_SEQ = "tns not sequential";
    string internal constant REQ_BAD_MERKLE = "failed Merkle proof check";
    // err message for dispute success reasons
    string internal constant RSN_BAD_INIT_TN = "invalid init tn";
    string internal constant RSN_BAD_ENCODING = "invalid encoding";
    string internal constant RSN_BAD_ACCT_ID = "invalid account id";
    string internal constant RSN_EVAL_FAILURE = "failed to evaluate";
    string internal constant RSN_BAD_POST_SROOT = "invalid post-state root";
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../libraries/DataTypes.sol";

library Transitions {
    // Transition Types
    uint8 public constant TN_TYPE_INVALID = 0;
    uint8 public constant TN_TYPE_INIT = 1;
    uint8 public constant TN_TYPE_DEPOSIT = 2;
    uint8 public constant TN_TYPE_WITHDRAW = 3;
    uint8 public constant TN_TYPE_BUY = 4;
    uint8 public constant TN_TYPE_SELL = 5;
    uint8 public constant TN_TYPE_XFER_ASSET = 6;
    uint8 public constant TN_TYPE_XFER_SHARE = 7;
    uint8 public constant TN_TYPE_AGGREGATE_ORDER = 8;
    uint8 public constant TN_TYPE_EXEC_RESULT = 9;
    uint8 public constant TN_TYPE_SETTLE = 10;
    uint8 public constant TN_TYPE_WITHDRAW_PROTO_FEE = 11;
    uint8 public constant TN_TYPE_XFER_OP_FEE = 12;

    // Staking / liquidity mining
    uint8 public constant TN_TYPE_STAKE = 13;
    uint8 public constant TN_TYPE_UNSTAKE = 14;
    uint8 public constant TN_TYPE_ADD_POOL = 15;
    uint8 public constant TN_TYPE_UPDATE_POOL = 16;
    uint8 public constant TN_TYPE_DEPOSIT_REWARD = 17;

    // fee encoding
    uint128 public constant UINT128_HIBIT = 2**127;

    function extractTransitionType(bytes memory _bytes) internal pure returns (uint8) {
        uint8 transitionType;
        assembly {
            transitionType := mload(add(_bytes, 0x20))
        }
        return transitionType;
    }

    function decodeInitTransition(bytes memory _rawBytes) internal pure returns (DataTypes.InitTransition memory) {
        (uint8 transitionType, bytes32 stateRoot) = abi.decode((_rawBytes), (uint8, bytes32));
        DataTypes.InitTransition memory transition = DataTypes.InitTransition(transitionType, stateRoot);
        return transition;
    }

    function decodePackedDepositTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.DepositTransition memory)
    {
        (uint128 infoCode, bytes32 stateRoot, address account, uint256 amount) =
            abi.decode((_rawBytes), (uint128, bytes32, address, uint256));
        (uint32 accountId, uint32 assetId, uint8 transitionType) = decodeDepositInfoCode(infoCode);
        DataTypes.DepositTransition memory transition =
            DataTypes.DepositTransition(transitionType, stateRoot, account, accountId, assetId, amount);
        return transition;
    }

    function decodeDepositInfoCode(uint128 _infoCode)
        internal
        pure
        returns (
            uint32, // accountId
            uint32, // assetId
            uint8 // transitionType
        )
    {
        (uint64 high, uint64 low) = splitUint128(_infoCode);
        (uint32 accountId, uint32 assetId) = splitUint64(high);
        uint8 transitionType = uint8(low);
        return (accountId, assetId, transitionType);
    }

    function decodePackedWithdrawTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.WithdrawTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, address account, uint256 amtfee, bytes32 r, bytes32 s) =
            abi.decode((_rawBytes), (uint256, bytes32, address, uint256, bytes32, bytes32));
        (uint32 accountId, uint32 assetId, uint64 timestamp, uint8 v, uint8 transitionType) =
            decodeWithdrawInfoCode(infoCode);
        (uint128 amount, uint128 fee) = splitUint256(amtfee);
        DataTypes.WithdrawTransition memory transition =
            DataTypes.WithdrawTransition(
                transitionType,
                stateRoot,
                account,
                accountId,
                assetId,
                amount,
                fee,
                timestamp,
                r,
                s,
                v
            );
        return transition;
    }

    function decodeWithdrawInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // accountId
            uint32, // assetId
            uint64, // timestamp
            uint8, // sig-v
            uint8 // transitionType
        )
    {
        (uint128 high, uint128 low) = splitUint256(_infoCode);
        (uint64 ids, uint64 timestamp) = splitUint128(high);
        (uint32 accountId, uint32 assetId) = splitUint64(ids);
        (uint8 v, uint8 transitionType) = splitUint16(uint16(low));
        return (accountId, assetId, timestamp, v, transitionType);
    }

    function decodePackedBuyTransition(bytes memory _rawBytes) internal pure returns (DataTypes.BuyTransition memory) {
        (uint256 infoCode, bytes32 stateRoot, uint256 amtfee, bytes32 r, bytes32 s) =
            abi.decode((_rawBytes), (uint256, bytes32, uint256, bytes32, bytes32));
        (uint32 accountId, uint32 strategyId, uint64 timestamp, uint128 maxSharePrice, uint8 v, uint8 transitionType) =
            decodeBuySellInfoCode(infoCode);
        (uint128 amount, uint128 fee) = splitUint256(amtfee);
        DataTypes.BuyTransition memory transition =
            DataTypes.BuyTransition(
                transitionType,
                stateRoot,
                accountId,
                strategyId,
                amount,
                maxSharePrice,
                fee,
                timestamp,
                r,
                s,
                v
            );
        return transition;
    }

    function decodePackedSellTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.SellTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, uint256 sharefee, bytes32 r, bytes32 s) =
            abi.decode((_rawBytes), (uint256, bytes32, uint256, bytes32, bytes32));
        (uint32 accountId, uint32 strategyId, uint64 timestamp, uint128 minSharePrice, uint8 v, uint8 transitionType) =
            decodeBuySellInfoCode(infoCode);
        (uint128 shares, uint128 fee) = splitUint256(sharefee);
        DataTypes.SellTransition memory transition =
            DataTypes.SellTransition(
                transitionType,
                stateRoot,
                accountId,
                strategyId,
                shares,
                minSharePrice,
                fee,
                timestamp,
                r,
                s,
                v
            );
        return transition;
    }

    function decodeBuySellInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // accountId
            uint32, // strategyId
            uint64, // timestamp
            uint128, // maxSharePrice or minSharePrice
            uint8, // sig-v
            uint8 // transitionType
        )
    {
        (uint128 h1, uint128 low) = splitUint256(_infoCode);
        (uint64 h2, uint64 timestamp) = splitUint128(h1);
        (uint32 accountId, uint32 strategyId) = splitUint64(h2);
        uint128 sharePrice = uint128(low >> 16);
        (uint8 v, uint8 transitionType) = splitUint16(uint16(low));
        return (accountId, strategyId, timestamp, sharePrice, v, transitionType);
    }

    function decodePackedTransferAssetTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.TransferAssetTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, address toAccount, uint256 amtfee, bytes32 r, bytes32 s) =
            abi.decode((_rawBytes), (uint256, bytes32, address, uint256, bytes32, bytes32));
        (uint32 assetId, uint32 fromAccountId, uint32 toAccountId, uint64 timestamp, uint8 v, uint8 transitionType) =
            decodeTransferInfoCode(infoCode);
        (uint128 amount, uint128 fee) = splitUint256(amtfee);
        DataTypes.TransferAssetTransition memory transition =
            DataTypes.TransferAssetTransition(
                transitionType,
                stateRoot,
                fromAccountId,
                toAccountId,
                toAccount,
                assetId,
                amount,
                fee,
                timestamp,
                r,
                s,
                v
            );
        return transition;
    }

    function decodePackedTransferShareTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.TransferShareTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, address toAccount, uint256 sharefee, bytes32 r, bytes32 s) =
            abi.decode((_rawBytes), (uint256, bytes32, address, uint256, bytes32, bytes32));
        (uint32 strategyId, uint32 fromAccountId, uint32 toAccountId, uint64 timestamp, uint8 v, uint8 transitionType) =
            decodeTransferInfoCode(infoCode);
        (uint128 shares, uint128 fee) = splitUint256(sharefee);
        DataTypes.TransferShareTransition memory transition =
            DataTypes.TransferShareTransition(
                transitionType,
                stateRoot,
                fromAccountId,
                toAccountId,
                toAccount,
                strategyId,
                shares,
                fee,
                timestamp,
                r,
                s,
                v
            );
        return transition;
    }

    function decodeTransferInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // assetId or strategyId
            uint32, // fromAccountId
            uint32, // toAccountId
            uint64, // timestamp
            uint8, // sig-v
            uint8 // transitionType
        )
    {
        (uint128 high, uint128 low) = splitUint256(_infoCode);
        (uint64 astId, uint64 acctIds) = splitUint128(high);
        (uint32 fromAccountId, uint32 toAccountId) = splitUint64(acctIds);
        (uint64 timestamp, uint64 vt) = splitUint128(low);
        (uint8 v, uint8 transitionType) = splitUint16(uint16(vt));
        return (uint32(astId), fromAccountId, toAccountId, timestamp, v, transitionType);
    }

    function decodePackedSettlementTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.SettlementTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot) = abi.decode((_rawBytes), (uint256, bytes32));
        (
            uint32 accountId,
            uint32 strategyId,
            uint64 aggregateId,
            uint128 celrRefund,
            uint128 assetRefund,
            uint8 transitionType
        ) = decodeSettlementInfoCode(infoCode);
        DataTypes.SettlementTransition memory transition =
            DataTypes.SettlementTransition(
                transitionType,
                stateRoot,
                strategyId,
                aggregateId,
                accountId,
                celrRefund,
                assetRefund
            );
        return transition;
    }

    function decodeSettlementInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // accountId
            uint32, // strategyId
            uint64, // aggregateId
            uint128, // celrRefund
            uint128, // assetRefund
            uint8 // transitionType
        )
    {
        uint128 ids = uint128(_infoCode >> 160);
        uint64 aggregateId = uint32(ids);
        ids = uint64(ids >> 32);
        uint32 strategyId = uint32(ids);
        uint32 accountId = uint32(ids >> 32);
        uint256 refund = uint152(_infoCode >> 8);
        uint128 assetRefund = uint96(refund);
        uint128 celrRefund = uint128(refund >> 96) * 1e9;
        uint8 transitionType = uint8(_infoCode);
        return (accountId, strategyId, aggregateId, celrRefund, assetRefund, transitionType);
    }

    function decodePackedAggregateOrdersTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.AggregateOrdersTransition memory)
    {
        (
            uint64 infoCode,
            bytes32 stateRoot,
            uint256 buyAmount,
            uint256 sellShares,
            uint256 minSharesFromBuy,
            uint256 minAmountFromSell
        ) = abi.decode((_rawBytes), (uint64, bytes32, uint256, uint256, uint256, uint256));
        (uint32 strategyId, uint8 transitionType) = decodeAggregateOrdersInfoCode(infoCode);
        DataTypes.AggregateOrdersTransition memory transition =
            DataTypes.AggregateOrdersTransition(
                transitionType,
                stateRoot,
                strategyId,
                buyAmount,
                sellShares,
                minSharesFromBuy,
                minAmountFromSell
            );
        return transition;
    }

    function decodeAggregateOrdersInfoCode(uint64 _infoCode)
        internal
        pure
        returns (
            uint32, // strategyId
            uint8 // transitionType
        )
    {
        (uint32 strategyId, uint32 low) = splitUint64(_infoCode);
        uint8 transitionType = uint8(low);
        return (strategyId, transitionType);
    }

    function decodePackedExecutionResultTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.ExecutionResultTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, uint256 sharesFromBuy, uint256 amountFromSell) =
            abi.decode((_rawBytes), (uint256, bytes32, uint256, uint256));
        (uint64 currEpoch, uint64 aggregateId, uint32 strategyId, bool success, uint8 transitionType) =
            decodeExecutionResultInfoCode(infoCode);
        DataTypes.ExecutionResultTransition memory transition =
            DataTypes.ExecutionResultTransition(
                transitionType,
                stateRoot,
                strategyId,
                aggregateId,
                success,
                sharesFromBuy,
                amountFromSell,
                currEpoch
            );
        return transition;
    }

    function decodeExecutionResultInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint64, // currEpoch,
            uint64, // aggregateId
            uint32, // strategyId
            bool, // success
            uint8 // transitionType
        )
    {
        (uint128 high, uint128 low) = splitUint256(_infoCode);
        (, uint64 currEpoch) = splitUint128(high);
        (uint64 aggregateId, uint64 low2) = splitUint128(low);
        (uint32 strategyId, uint32 low3) = splitUint64(low2);
        uint8 transitionType = uint8(low3);
        bool success = uint8(low3 >> 8) == 1;
        return (currEpoch, aggregateId, strategyId, success, transitionType);
    }

    function decodePackedStakeTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.StakeTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, uint256 sharefee, bytes32 r, bytes32 s) =
            abi.decode((_rawBytes), (uint256, bytes32, uint256, bytes32, bytes32));
        (uint32 poolId, uint32 accountId, uint64 timestamp, uint8 v, uint8 transitionType) =
            decodeStakingInfoCode(infoCode);
        (uint128 shares, uint128 fee) = splitUint256(sharefee);
        DataTypes.StakeTransition memory transition =
            DataTypes.StakeTransition(transitionType, stateRoot, poolId, accountId, shares, fee, timestamp, r, s, v);
        return transition;
    }

    function decodePackedUnstakeTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.UnstakeTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, uint256 sharefee, bytes32 r, bytes32 s) =
            abi.decode((_rawBytes), (uint256, bytes32, uint256, bytes32, bytes32));
        (uint32 poolId, uint32 accountId, uint64 timestamp, uint8 v, uint8 transitionType) =
            decodeStakingInfoCode(infoCode);
        (uint128 shares, uint128 fee) = splitUint256(sharefee);
        DataTypes.UnstakeTransition memory transition =
            DataTypes.UnstakeTransition(transitionType, stateRoot, poolId, accountId, shares, fee, timestamp, r, s, v);
        return transition;
    }

    function decodeStakingInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // poolId
            uint32, // accountId
            uint64, // timestamp
            uint8, // sig-v
            uint8 // transitionType
        )
    {
        (uint128 high, uint128 low) = splitUint256(_infoCode);
        (, uint64 poolIdAccountId) = splitUint128(high);
        (uint32 poolId, uint32 accountId) = splitUint64(poolIdAccountId);
        (uint64 timestamp, uint64 vt) = splitUint128(low);
        (uint8 v, uint8 transitionType) = splitUint16(uint16(vt));
        return (poolId, accountId, timestamp, v, transitionType);
    }

    function decodeAddPoolTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.AddPoolTransition memory)
    {
        (
            uint8 transitionType,
            bytes32 stateRoot,
            uint32 poolId,
            uint32 strategyId,
            uint32[] memory rewardAssetIds,
            uint256[] memory rewardPerEpoch,
            uint256 stakeAdjustmentFactor,
            uint64 startEpoch
        ) = abi.decode((_rawBytes), (uint8, bytes32, uint32, uint32, uint32[], uint256[], uint256, uint64));
        DataTypes.AddPoolTransition memory transition =
            DataTypes.AddPoolTransition(
                transitionType,
                stateRoot,
                poolId,
                strategyId,
                rewardAssetIds,
                rewardPerEpoch,
                stakeAdjustmentFactor,
                startEpoch
            );
        return transition;
    }

    function decodeUpdatePoolTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.UpdatePoolTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 poolId, uint256[] memory rewardPerEpoch) =
            abi.decode((_rawBytes), (uint8, bytes32, uint32, uint256[]));
        DataTypes.UpdatePoolTransition memory transition =
            DataTypes.UpdatePoolTransition(transitionType, stateRoot, poolId, rewardPerEpoch);
        return transition;
    }

    function decodeDepositRewardTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.DepositRewardTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 assetId, uint256 amount) =
            abi.decode((_rawBytes), (uint8, bytes32, uint32, uint256));
        DataTypes.DepositRewardTransition memory transition =
            DataTypes.DepositRewardTransition(transitionType, stateRoot, assetId, amount);
        return transition;
    }

    function decodeWithdrawProtocolFeeTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.WithdrawProtocolFeeTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 assetId, uint256 amount) =
            abi.decode((_rawBytes), (uint8, bytes32, uint32, uint256));
        DataTypes.WithdrawProtocolFeeTransition memory transition =
            DataTypes.WithdrawProtocolFeeTransition(transitionType, stateRoot, assetId, amount);
        return transition;
    }

    function decodeTransferOperatorFeeTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.TransferOperatorFeeTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 accountId) = abi.decode((_rawBytes), (uint8, bytes32, uint32));
        DataTypes.TransferOperatorFeeTransition memory transition =
            DataTypes.TransferOperatorFeeTransition(transitionType, stateRoot, accountId);
        return transition;
    }

    /**
     * Helper to expand the account array of idle assets if needed.
     */
    function adjustAccountIdleAssetEntries(DataTypes.AccountInfo memory _accountInfo, uint32 assetId) internal pure {
        uint32 n = uint32(_accountInfo.idleAssets.length);
        if (n <= assetId) {
            uint256[] memory arr = new uint256[](assetId + 1);
            for (uint32 i = 0; i < n; i++) {
                arr[i] = _accountInfo.idleAssets[i];
            }
            for (uint32 i = n; i <= assetId; i++) {
                arr[i] = 0;
            }
            _accountInfo.idleAssets = arr;
        }
    }

    /**
     * Helper to expand the account array of shares if needed.
     */
    function adjustAccountShareEntries(DataTypes.AccountInfo memory _accountInfo, uint32 stId) internal pure {
        uint32 n = uint32(_accountInfo.shares.length);
        if (n <= stId) {
            uint256[] memory arr = new uint256[](stId + 1);
            for (uint32 i = 0; i < n; i++) {
                arr[i] = _accountInfo.shares[i];
            }
            for (uint32 i = n; i <= stId; i++) {
                arr[i] = 0;
            }
            _accountInfo.shares = arr;
        }
    }

    /**
     * Helper to expand protocol fee array (if needed) and add given fee.
     */
    function addProtoFee(
        DataTypes.GlobalInfo memory _globalInfo,
        uint32 _assetId,
        uint256 _fee
    ) internal pure {
        _globalInfo.protoFees = adjustUint256Array(_globalInfo.protoFees, _assetId);
        _globalInfo.protoFees[_assetId] += _fee;
    }

    /**
     * Helper to expand the chosen operator fee array (if needed) and add a given fee.
     * If "_assets" is true, use the assets fee array, otherwise use the shares fee array.
     */
    function updateOpFee(
        DataTypes.GlobalInfo memory _globalInfo,
        bool _assets,
        uint32 _idx,
        uint256 _fee
    ) internal pure {
        if (_assets) {
            _globalInfo.opFees.assets = adjustUint256Array(_globalInfo.opFees.assets, _idx);
            _globalInfo.opFees.assets[_idx] += _fee;
        } else {
            _globalInfo.opFees.shares = adjustUint256Array(_globalInfo.opFees.shares, _idx);
            _globalInfo.opFees.shares[_idx] += _fee;
        }
    }

    /**
     * Helper to expand an array of uint256, e.g. the various fee arrays in globalInfo.
     * Takes the array and the needed index and returns the unchanged array or a new expanded one.
     */
    function adjustUint256Array(uint256[] memory _array, uint32 _idx) internal pure returns (uint256[] memory) {
        uint32 n = uint32(_array.length);
        if (_idx < n) {
            return _array;
        }

        uint256[] memory newArray = new uint256[](_idx + 1);
        for (uint32 i = 0; i < n; i++) {
            newArray[i] = _array[i];
        }
        for (uint32 i = n; i <= _idx; i++) {
            newArray[i] = 0;
        }

        return newArray;
    }

    /**
     * Helper to get the fee type and amount.
     * Returns (isCelr, fee).
     */
    function getFeeInfo(uint128 _fee) internal pure returns (bool, uint256) {
        bool isCelr = _fee & UINT128_HIBIT == UINT128_HIBIT;
        if (isCelr) {
            _fee = _fee ^ UINT128_HIBIT;
        }
        return (isCelr, uint256(_fee));
    }

    function splitUint16(uint16 _code) internal pure returns (uint8, uint8) {
        uint8 high = uint8(_code >> 8);
        uint8 low = uint8(_code);
        return (high, low);
    }

    function splitUint64(uint64 _code) internal pure returns (uint32, uint32) {
        uint32 high = uint32(_code >> 32);
        uint32 low = uint32(_code);
        return (high, low);
    }

    function splitUint128(uint128 _code) internal pure returns (uint64, uint64) {
        uint64 high = uint64(_code >> 64);
        uint64 low = uint64(_code);
        return (high, low);
    }

    function splitUint256(uint256 _code) internal pure returns (uint128, uint128) {
        uint128 high = uint128(_code >> 128);
        uint128 low = uint128(_code);
        return (high, low);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface for DeFi strategies
 * @notice Strategy provides abstraction for a DeFi strategy.
 */
interface IStrategy {
    event Buy(uint256 amount, uint256 sharesFromBuy);

    event Sell(uint256 shares, uint256 amountFromSell);

    event ControllerChanged(address previousController, address newController);

    /**
     * @notice Returns the address of the asset token.
     */
    function getAssetAddress() external view returns (address);

    /**
     * @notice aggregate orders to strategy per instructions from L2.
     *
     * @param _buyAmount The aggregated asset amount to buy.
     * @param _sellShares The aggregated shares to sell.
     * @param _minSharesFromBuy Minimal shares from buy.
     * @param _minAmountFromSell Minimal asset amount from sell.
     * @return (sharesFromBuy, amountFromSell)
     */
    function aggregateOrders(
        uint256 _buyAmount,
        uint256 _sellShares,
        uint256 _minSharesFromBuy,
        uint256 _minAmountFromSell
    ) external returns (uint256, uint256);

    /**
     * @notice Syncs and returns the price of each share
     */
    function syncPrice() external returns (uint256);

    /**
     * @notice Compounding of extra yields
     */
    function harvest() external;
}

