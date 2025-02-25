/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/provableAPI.sol

// SPDX-License-Identifier: UNLICENSED
// <provableAPI>
/*
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016-2019 Oraclize LTD
Copyright (c) 2019-2020 Provable Things Limited
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
pragma solidity =0.8.4;

// Dummy contract only used to emit to end-user they are using wrong solc
abstract contract solcChecker {
    /* INCOMPATIBLE SOLC: import the following instead: "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol" */
    function f(bytes calldata x) external virtual;
}

interface ProvableI {
    function cbAddress() external returns (address _cbAddress);

    function setProofType(bytes1 _proofType) external;

    function setCustomGasPrice(uint256 _gasPrice) external;

    function getPrice(string calldata _datasource)
        external
        returns (uint256 _dsprice);

    function randomDS_getSessionPubKeyHash()
        external
        view
        returns (bytes32 _sessionKeyHash);

    function getPrice(string calldata _datasource, uint256 _gasLimit)
        external
        returns (uint256 _dsprice);

    function queryN(
        uint256 _timestamp,
        string calldata _datasource,
        bytes calldata _argN
    ) external payable returns (bytes32 _id);

    function query(
        uint256 _timestamp,
        string calldata _datasource,
        string calldata _arg
    ) external payable returns (bytes32 _id);

    function query2(
        uint256 _timestamp,
        string calldata _datasource,
        string calldata _arg1,
        string calldata _arg2
    ) external payable returns (bytes32 _id);

    function query_withGasLimit(
        uint256 _timestamp,
        string calldata _datasource,
        string calldata _arg,
        uint256 _gasLimit
    ) external payable returns (bytes32 _id);

    function queryN_withGasLimit(
        uint256 _timestamp,
        string calldata _datasource,
        bytes calldata _argN,
        uint256 _gasLimit
    ) external payable returns (bytes32 _id);

    function query2_withGasLimit(
        uint256 _timestamp,
        string calldata _datasource,
        string calldata _arg1,
        string calldata _arg2,
        uint256 _gasLimit
    ) external payable returns (bytes32 _id);
}

interface OracleAddrResolverI {
    function getAddress() external returns (address _address);
}

/*
Begin solidity-cborutils
https://github.com/smartcontractkit/solidity-cborutils
MIT License
Copyright (c) 2018 SmartContract ChainLink, Ltd.
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
library Buffer {
    struct buffer {
        bytes buf;
        uint256 capacity;
    }

    function init(buffer memory _buf, uint256 _capacity) internal pure {
        uint256 capacity = _capacity;
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        _buf.capacity = capacity; // Allocate space for the buffer data
        assembly {
            let ptr := mload(0x40)
            mstore(_buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory _buf, uint256 _capacity) private pure {
        bytes memory oldbuf = _buf.buf;
        init(_buf, _capacity);
        append(_buf, oldbuf);
    }

    function max(uint256 _a, uint256 _b) private pure returns (uint256 _max) {
        if (_a > _b) {
            return _a;
        }
        return _b;
    }

    /**
     * @dev Appends a byte array to the end of the buffer. Resizes if doing so
     *      would exceed the capacity of the buffer.
     * @param _buf The buffer to append to.
     * @param _data The data to append.
     * @return _buffer The original buffer.
     *
     */
    function append(buffer memory _buf, bytes memory _data)
        internal
        pure
        returns (buffer memory _buffer)
    {
        if (_data.length + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _data.length) * 2);
        }
        uint256 dest;
        uint256 src;
        uint256 len = _data.length;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            dest := add(add(bufptr, buflen), 32) // Start address = buffer address + buffer length + sizeof(buffer length)
            mstore(bufptr, add(buflen, mload(_data))) // Update buffer length
            src := add(_data, 32)
        }
        for (; len >= 32; len -= 32) {
            // Copy word-length chunks while possible
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        uint256 mask = 256**(32 - len) - 1; // Copy remaining bytes
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
        return _buf;
    }

    /**
     *
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param _buf The buffer to append to.
     * @param _data The data to append.
     *
     */
    function append(buffer memory _buf, uint8 _data) internal pure {
        if (_buf.buf.length + 1 > _buf.capacity) {
            resize(_buf, _buf.capacity * 2);
        }
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), 32) // Address = buffer address + buffer length + sizeof(buffer length)
            mstore8(dest, _data)
            mstore(bufptr, add(buflen, 1)) // Update buffer length
        }
    }

    /**
     *
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param _buf The buffer to append to.
     * @param _data The data to append.
     * @return _buffer The original buffer.
     *
     */
    function appendInt(
        buffer memory _buf,
        uint256 _data,
        uint256 _len
    ) internal pure returns (buffer memory _buffer) {
        if (_len + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _len) * 2);
        }
        uint256 mask = 256**_len - 1;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), _len) // Address = buffer address + buffer length + sizeof(buffer length) + len
            mstore(dest, or(and(mload(dest), not(mask)), _data))
            mstore(bufptr, add(buflen, _len)) // Update buffer length
        }
        return _buf;
    }
}

library CBOR {
    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(
        Buffer.buffer memory _buf,
        uint8 _major,
        uint256 _value
    ) private pure {
        if (_value <= 23) {
            _buf.append(uint8((_major << 5) | _value));
        } else if (_value <= 0xFF) {
            _buf.append(uint8((_major << 5) | 24));
            _buf.appendInt(_value, 1);
        } else if (_value <= 0xFFFF) {
            _buf.append(uint8((_major << 5) | 25));
            _buf.appendInt(_value, 2);
        } else if (_value <= 0xFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 26));
            _buf.appendInt(_value, 4);
        } else if (_value <= 0xFFFFFFFFFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 27));
            _buf.appendInt(_value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory _buf, uint8 _major)
        private
        pure
    {
        _buf.append(uint8((_major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory _buf, uint256 _value)
        internal
        pure
    {
        encodeType(_buf, MAJOR_TYPE_INT, _value);
    }

    function encodeInt(Buffer.buffer memory _buf, int256 _value) internal pure {
        if (_value >= 0) {
            encodeType(_buf, MAJOR_TYPE_INT, uint256(_value));
        } else {
            encodeType(_buf, MAJOR_TYPE_NEGATIVE_INT, uint256(-1 - _value));
        }
    }

    function encodeBytes(Buffer.buffer memory _buf, bytes memory _value)
        internal
        pure
    {
        encodeType(_buf, MAJOR_TYPE_BYTES, _value.length);
        _buf.append(_value);
    }

    function encodeString(Buffer.buffer memory _buf, string memory _value)
        internal
        pure
    {
        encodeType(_buf, MAJOR_TYPE_STRING, bytes(_value).length);
        _buf.append(bytes(_value));
    }

    function startArray(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

/*
End solidity-cborutils
*/
contract usingProvable {
    using CBOR for Buffer.buffer;

    ProvableI provable;
    OracleAddrResolverI OAR;

    uint256 constant day = 60 * 60 * 24;
    uint256 constant week = 60 * 60 * 24 * 7;
    uint256 constant month = 60 * 60 * 24 * 30;

    bytes1 constant proofType_NONE = 0x00;
    bytes1 constant proofType_Ledger = 0x30;
    bytes1 constant proofType_Native = 0xF0;
    bytes1 constant proofStorage_IPFS = 0x01;
    bytes1 constant proofType_Android = 0x40;
    bytes1 constant proofType_TLSNotary = 0x10;

    string provable_network_name;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_consensys = 161;

    mapping(bytes32 => bytes32) provable_randomDS_args;
    mapping(bytes32 => bool) provable_randomDS_sessionKeysHashVerified;

    modifier provableAPI {
        if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
            provable_setNetwork(networkID_auto);
        }
        if (address(provable) != OAR.getAddress()) {
            provable = ProvableI(OAR.getAddress());
        }
        _;
    }

    modifier provable_randomDS_proofVerify(
        bytes32 _queryId,
        string memory _result,
        bytes memory _proof
    ) {
        // RandomDS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        require(
            (_proof[0] == 'L') &&
                (_proof[1] == 'P') &&
                (uint8(_proof[2]) == uint8(1))
        );
        bool proofVerified =
            provable_randomDS_proofVerify__main(
                _proof,
                _queryId,
                bytes(_result),
                provable_getNetworkName()
            );
        require(proofVerified);
        _;
    }

    function provable_setNetwork(uint8 _networkID)
        internal
        returns (bool _networkSet)
    {
        _networkID; // NOTE: Silence the warning and remain backwards compatible
        return provable_setNetwork();
    }

    function provable_setNetworkName(string memory _network_name) internal {
        provable_network_name = _network_name;
    }

    function provable_getNetworkName()
        internal
        view
        returns (string memory _networkName)
    {
        return provable_network_name;
    }

    function provable_setNetwork() internal returns (bool _networkSet) {
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0) {
            //mainnet
            OAR = OracleAddrResolverI(
                0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed
            );
            provable_setNetworkName('eth_mainnet');
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1) > 0) {
            //ropsten testnet
            OAR = OracleAddrResolverI(
                0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1
            );
            provable_setNetworkName('eth_ropsten3');
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0) {
            //kovan testnet
            OAR = OracleAddrResolverI(
                0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e
            );
            provable_setNetworkName('eth_kovan');
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48) > 0) {
            //rinkeby testnet
            OAR = OracleAddrResolverI(
                0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48
            );
            provable_setNetworkName('eth_rinkeby');
            return true;
        }
        if (getCodeSize(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41) > 0) {
            //goerli testnet
            OAR = OracleAddrResolverI(
                0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41
            );
            provable_setNetworkName('eth_goerli');
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475) > 0) {
            //ethereum-bridge
            OAR = OracleAddrResolverI(
                0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475
            );
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF) > 0) {
            //ether.camp ide
            OAR = OracleAddrResolverI(
                0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF
            );
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA) > 0) {
            //browser-solidity
            OAR = OracleAddrResolverI(
                0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA
            );
            return true;
        }
        return false;
    }

    /**
     * @dev The following `__callback` functions are just placeholders ideally
     *      meant to be defined in child contract when proofs are used.
     *      The function bodies simply silence compiler warnings.
     */
    function __callback(bytes32 _myid, string memory _result) public virtual {
        __callback(_myid, _result, new bytes(0));
    }

    function __callback(
        bytes32 _myid,
        string memory _result,
        bytes memory _proof
    ) public virtual {
        _myid;
        _result;
        _proof;
        provable_randomDS_args[bytes32(0)] = bytes32(0);
    }

    function provable_getPrice(string memory _datasource)
        internal
        provableAPI
        returns (uint256 _queryPrice)
    {
        return provable.getPrice(_datasource);
    }

    function provable_getPrice(string memory _datasource, uint256 _gasLimit)
        internal
        provableAPI
        returns (uint256 _queryPrice)
    {
        return provable.getPrice(_datasource, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        uint256 price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query{value: price}(0, _datasource, _arg);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string memory _arg
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query{value: price}(_timestamp, _datasource, _arg);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string memory _arg,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return
            provable.query_withGasLimit{value: price}(
                _timestamp,
                _datasource,
                _arg,
                _gasLimit
            );
    }

    function provable_query(
        string memory _datasource,
        string memory _arg,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return
            provable.query_withGasLimit{value: price}(
                0,
                _datasource,
                _arg,
                _gasLimit
            );
    }

    function provable_query(
        string memory _datasource,
        string memory _arg1,
        string memory _arg2
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query2{value: price}(0, _datasource, _arg1, _arg2);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string memory _arg1,
        string memory _arg2
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return
            provable.query2{value: price}(
                _timestamp,
                _datasource,
                _arg1,
                _arg2
            );
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string memory _arg1,
        string memory _arg2,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return
            provable.query2_withGasLimit{value: price}(
                _timestamp,
                _datasource,
                _arg1,
                _arg2,
                _gasLimit
            );
    }

    function provable_query(
        string memory _datasource,
        string memory _arg1,
        string memory _arg2,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return
            provable.query2_withGasLimit{value: price}(
                0,
                _datasource,
                _arg1,
                _arg2,
                _gasLimit
            );
    }

    function provable_query(string memory _datasource, string[] memory _argN)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        uint256 price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN{value: price}(0, _datasource, args);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string[] memory _argN
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN{value: price}(_timestamp, _datasource, args);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string[] memory _argN,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return
            provable.queryN_withGasLimit{value: price}(
                _timestamp,
                _datasource,
                args,
                _gasLimit
            );
    }

    function provable_query(
        string memory _datasource,
        string[] memory _argN,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return
            provable.queryN_withGasLimit{value: price}(
                0,
                _datasource,
                args,
                _gasLimit
            );
    }

    function provable_query(string memory _datasource, string[1] memory _args)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string[1] memory _args
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string[1] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(
        string memory _datasource,
        string[1] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[2] memory _args)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string[2] memory _args
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string[2] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(
        string memory _datasource,
        string[2] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[3] memory _args)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string[3] memory _args
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string[3] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(
        string memory _datasource,
        string[3] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[4] memory _args)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string[4] memory _args
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string[4] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(
        string memory _datasource,
        string[4] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[5] memory _args)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string[5] memory _args
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        string[5] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(
        string memory _datasource,
        string[5] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[] memory _argN)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        uint256 price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN{value: price}(0, _datasource, args);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        bytes[] memory _argN
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN{value: price}(_timestamp, _datasource, args);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        bytes[] memory _argN,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return
            provable.queryN_withGasLimit{value: price}(
                _timestamp,
                _datasource,
                args,
                _gasLimit
            );
    }

    function provable_query(
        string memory _datasource,
        bytes[] memory _argN,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        uint256 price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return
            provable.queryN_withGasLimit{value: price}(
                0,
                _datasource,
                args,
                _gasLimit
            );
    }

    function provable_query(string memory _datasource, bytes[1] memory _args)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        bytes[1] memory _args
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        bytes[1] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(
        string memory _datasource,
        bytes[1] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[2] memory _args)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        bytes[2] memory _args
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        bytes[2] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(
        string memory _datasource,
        bytes[2] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[3] memory _args)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        bytes[3] memory _args
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        bytes[3] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(
        string memory _datasource,
        bytes[3] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[4] memory _args)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        bytes[4] memory _args
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        bytes[4] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(
        string memory _datasource,
        bytes[4] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[5] memory _args)
        internal
        provableAPI
        returns (bytes32 _id)
    {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        bytes[5] memory _args
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(
        uint256 _timestamp,
        string memory _datasource,
        bytes[5] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(
        string memory _datasource,
        bytes[5] memory _args,
        uint256 _gasLimit
    ) internal provableAPI returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_setProof(bytes1 _proofP) internal provableAPI {
        return provable.setProofType(_proofP);
    }

    function provable_cbAddress()
        internal
        provableAPI
        returns (address _callbackAddress)
    {
        return provable.cbAddress();
    }

    function getCodeSize(address _addr) internal view returns (uint256 _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function provable_setCustomGasPrice(uint256 _gasPrice)
        internal
        provableAPI
    {
        return provable.setCustomGasPrice(_gasPrice);
    }

    function provable_randomDS_getSessionPubKeyHash()
        internal
        provableAPI
        returns (bytes32 _sessionKeyHash)
    {
        return provable.randomDS_getSessionPubKeyHash();
    }

    function parseAddr(string memory _a)
        internal
        pure
        returns (address _parsedAddress)
    {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint256 i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function strCompare(string memory _a, string memory _b)
        internal
        pure
        returns (int256 _returnCode)
    {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint256 minLength = a.length;
        if (b.length < minLength) {
            minLength = b.length;
        }
        for (uint256 i = 0; i < minLength; i++) {
            if (a[i] < b[i]) {
                return -1;
            } else if (a[i] > b[i]) {
                return 1;
            }
        }
        if (a.length < b.length) {
            return -1;
        } else if (a.length > b.length) {
            return 1;
        } else {
            return 0;
        }
    }

    function indexOf(string memory _haystack, string memory _needle)
        internal
        pure
        returns (int256 _returnCode)
    {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) {
            return -1;
        } else if (h.length > (2**128 - 1)) {
            return -1;
        } else {
            uint256 subindex = 0;
            for (uint256 i = 0; i < h.length; i++) {
                if (h[i] == n[0]) {
                    subindex = 1;
                    while (
                        subindex < n.length &&
                        (i + subindex) < h.length &&
                        h[i + subindex] == n[subindex]
                    ) {
                        subindex++;
                    }
                    if (subindex == n.length) {
                        return int256(i);
                    }
                }
            }
            return -1;
        }
    }

    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory _concatenatedString)
    {
        return strConcat(_a, _b, '', '', '');
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, '', '');
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, '');
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde =
            new string(
                _ba.length + _bb.length + _bc.length + _bd.length + _be.length
            );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        uint256 i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }

    function stra2cbor(string[] memory _arr)
        internal
        pure
        returns (bytes memory _cborEncoding)
    {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint256 i = 0; i < _arr.length; i++) {
            buf.encodeString(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] memory _arr)
        internal
        pure
        returns (bytes memory _cborEncoding)
    {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint256 i = 0; i < _arr.length; i++) {
            buf.encodeBytes(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function provable_newRandomDSQuery(
        uint256 _delay,
        uint256 _nbytes,
        uint256 _customGasLimit
    ) internal returns (bytes32 _queryId) {
        require((_nbytes > 0) && (_nbytes <= 32));
        _delay *= 10; // Convert from seconds to ledger timer ticks
        bytes memory nbytes = new bytes(1);
        nbytes[0] = bytes1(uint8(_nbytes));
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 =
            provable_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            /*
             The following variables can be relaxed.
             Check the relaxed random contract at https://github.com/oraclize/ethereum-examples
             for an idea on how to override and replace commit hash variables.
            */
            mstore(
                add(unonce, 0x20),
                xor(blockhash(sub(number(), 1)), xor(coinbase(), timestamp()))
            )
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly {
            mstore(add(delay, 0x20), _delay)
        }
        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);
        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = provable_query('random', args, _customGasLimit);
        bytes memory delay_bytes8_left = new bytes(8);
        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(
                add(delay_bytes8_left, 0x27),
                div(
                    x,
                    0x100000000000000000000000000000000000000000000000000000000000000
                )
            )
            mstore8(
                add(delay_bytes8_left, 0x26),
                div(
                    x,
                    0x1000000000000000000000000000000000000000000000000000000000000
                )
            )
            mstore8(
                add(delay_bytes8_left, 0x25),
                div(
                    x,
                    0x10000000000000000000000000000000000000000000000000000000000
                )
            )
            mstore8(
                add(delay_bytes8_left, 0x24),
                div(
                    x,
                    0x100000000000000000000000000000000000000000000000000000000
                )
            )
            mstore8(
                add(delay_bytes8_left, 0x23),
                div(
                    x,
                    0x1000000000000000000000000000000000000000000000000000000
                )
            )
            mstore8(
                add(delay_bytes8_left, 0x22),
                div(x, 0x10000000000000000000000000000000000000000000000000000)
            )
            mstore8(
                add(delay_bytes8_left, 0x21),
                div(x, 0x100000000000000000000000000000000000000000000000000)
            )
            mstore8(
                add(delay_bytes8_left, 0x20),
                div(x, 0x1000000000000000000000000000000000000000000000000)
            )
        }
        provable_randomDS_setCommitment(
            queryId,
            keccak256(
                abi.encodePacked(
                    delay_bytes8_left,
                    args[1],
                    sha256(args[0]),
                    args[2]
                )
            )
        );
        return queryId;
    }

    function provable_randomDS_setCommitment(
        bytes32 _queryId,
        bytes32 _commitment
    ) internal {
        provable_randomDS_args[_queryId] = _commitment;
    }

    function verifySig(
        bytes32 _tosignh,
        bytes memory _dersig,
        bytes memory _pubkey
    ) internal returns (bool _sigVerified) {
        bool sigok;
        address signer;
        bytes32 sigr;
        bytes32 sigs;
        bytes memory sigr_ = new bytes(32);
        uint256 offset = 4 + (uint256(uint8(_dersig[3])) - 0x20);
        sigr_ = copyBytes(_dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(
            _dersig,
            offset + (uint256(uint8(_dersig[offset - 1])) - 0x20),
            32,
            sigs_,
            0
        );
        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }
        (sigok, signer) = safer_ecrecover(_tosignh, 27, sigr, sigs);
        if (address(uint160(uint256(keccak256(_pubkey)))) == signer) {
            return true;
        } else {
            (sigok, signer) = safer_ecrecover(_tosignh, 28, sigr, sigs);
            return (address(uint160(uint256(keccak256(_pubkey)))) == signer);
        }
    }

    function provable_randomDS_proofVerify__sessionKeyValidity(
        bytes memory _proof,
        uint256 _sig2offset
    ) internal returns (bool _proofVerified) {
        bool sigok;
        // Random DS Proof Step 6: Verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 =
            new bytes(uint256(uint8(_proof[_sig2offset + 1])) + 2);
        copyBytes(_proof, _sig2offset, sig2.length, sig2, 0);
        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(_proof, 3 + 1, 64, appkey1_pubkey, 0);
        bytes memory tosign2 = new bytes(1 + 65 + 32);
        tosign2[0] = bytes1(uint8(1)); //role
        copyBytes(_proof, _sig2offset - 65, 65, tosign2, 1);
        bytes memory CODEHASH =
            hex'fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c';
        copyBytes(CODEHASH, 0, 32, tosign2, 1 + 65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);
        if (!sigok) {
            return false;
        }
        // Random DS Proof Step 7: Verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY =
            hex'7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4';
        bytes memory tosign3 = new bytes(1 + 65);
        tosign3[0] = 0xFE;
        copyBytes(_proof, 3, 65, tosign3, 1);
        bytes memory sig3 = new bytes(uint256(uint8(_proof[3 + 65 + 1])) + 2);
        copyBytes(_proof, 3 + 65, sig3.length, sig3, 0);
        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);
        return sigok;
    }

    function provable_randomDS_proofVerify__returnCode(
        bytes32 _queryId,
        string memory _result,
        bytes memory _proof
    ) internal returns (uint8 _returnCode) {
        // Random DS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        if (
            (_proof[0] != 'L') ||
            (_proof[1] != 'P') ||
            (uint8(_proof[2]) != uint8(1))
        ) {
            return 1;
        }
        bool proofVerified =
            provable_randomDS_proofVerify__main(
                _proof,
                _queryId,
                bytes(_result),
                provable_getNetworkName()
            );
        if (!proofVerified) {
            return 2;
        }
        return 0;
    }

    function matchBytes32Prefix(
        bytes32 _content,
        bytes memory _prefix,
        uint256 _nRandomBytes
    ) internal pure returns (bool _matchesPrefix) {
        bool match_ = true;
        require(_prefix.length == _nRandomBytes);
        for (uint256 i = 0; i < _nRandomBytes; i++) {
            if (_content[i] != _prefix[i]) {
                match_ = false;
            }
        }
        return match_;
    }

    function provable_randomDS_proofVerify__main(
        bytes memory _proof,
        bytes32 _queryId,
        bytes memory _result,
        string memory _contextName
    ) internal returns (bool _proofVerified) {
        // Random DS Proof Step 2: The unique keyhash has to match with the sha256 of (context name + _queryId)
        uint256 ledgerProofLength =
            3 + 65 + (uint256(uint8(_proof[3 + 65 + 1])) + 2) + 32;
        bytes memory keyhash = new bytes(32);
        copyBytes(_proof, ledgerProofLength, 32, keyhash, 0);
        if (
            !(keccak256(keyhash) ==
                keccak256(
                    abi.encodePacked(
                        sha256(abi.encodePacked(_contextName, _queryId))
                    )
                ))
        ) {
            return false;
        }
        bytes memory sig1 =
            new bytes(
                uint256(
                    uint8(_proof[ledgerProofLength + (32 + 8 + 1 + 32) + 1])
                ) + 2
            );
        copyBytes(
            _proof,
            ledgerProofLength + (32 + 8 + 1 + 32),
            sig1.length,
            sig1,
            0
        );
        // Random DS Proof Step 3: We assume sig1 is valid (it will be verified during step 5) and we verify if '_result' is the _prefix of sha256(sig1)
        if (
            !matchBytes32Prefix(
                sha256(sig1),
                _result,
                uint256(uint8(_proof[ledgerProofLength + 32 + 8]))
            )
        ) {
            return false;
        }
        // Random DS Proof Step 4: Commitment match verification, keccak256(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8 + 1 + 32);
        copyBytes(
            _proof,
            ledgerProofLength + 32,
            8 + 1 + 32,
            commitmentSlice1,
            0
        );
        bytes memory sessionPubkey = new bytes(64);
        uint256 sig2offset =
            ledgerProofLength + 32 + (8 + 1 + 32) + sig1.length + 65;
        copyBytes(_proof, sig2offset - 64, 64, sessionPubkey, 0);
        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (
            provable_randomDS_args[_queryId] ==
            keccak256(abi.encodePacked(commitmentSlice1, sessionPubkeyHash))
        ) {
            //unonce, nbytes and sessionKeyHash match
            delete provable_randomDS_args[_queryId];
        } else return false;
        // Random DS Proof Step 5: Validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32 + 8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength, 32 + 8 + 1 + 32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) {
            return false;
        }
        // Verify if sessionPubkeyHash was verified already, if not.. let's do it!
        if (!provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash]) {
            provable_randomDS_sessionKeysHashVerified[
                sessionPubkeyHash
            ] = provable_randomDS_proofVerify__sessionKeyValidity(
                _proof,
                sig2offset
            );
        }
        return provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }

    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    */
    function copyBytes(
        bytes memory _from,
        uint256 _fromOffset,
        uint256 _length,
        bytes memory _to,
        uint256 _toOffset
    ) internal pure returns (bytes memory _copiedBytes) {
        uint256 minLength = _length + _toOffset;
        require(_to.length >= minLength); // Buffer too small. Should be a better way?
        uint256 i = 32 + _fromOffset; // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint256 j = 32 + _toOffset;
        while (i < (32 + _fromOffset + _length)) {
            assembly {
                let tmp := mload(add(_from, i))
                mstore(add(_to, j), tmp)
            }
            i += 32;
            j += 32;
        }
        return _to;
    }

    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
     Duplicate Solidity's ecrecover, but catching the CALL return value
    */
    function safer_ecrecover(
        bytes32 _hash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal returns (bool _success, address _recoveredAddress) {
        /*
         We do our own memory management here. Solidity uses memory offset
         0x40 to store the current end of memory. We write past it (as
         writes are memory extensions), but don't update the offset so
         Solidity will reuse it. The memory used here is only needed for
         this context.
         FIXME: inline assembly can't access return values
        */
        bool ret;
        address addr;
        assembly {
            let size := mload(0x40)
            mstore(size, _hash)
            mstore(add(size, 32), _v)
            mstore(add(size, 64), _r)
            mstore(add(size, 96), _s)
            ret := call(3000, 1, 0, size, 128, size, 32) // NOTE: we can reuse the request memory because we deal with the return code.
            addr := mload(size)
        }
        return (ret, addr);
    }

    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    */
    function ecrecovery(bytes32 _hash, bytes memory _sig)
        internal
        returns (bool _success, address _recoveredAddress)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_sig.length != 65) {
            return (false, address(0));
        }
        /*
         The signature format is a compact form of:
           {bytes32 r}{bytes32 s}{uint8 v}
         Compact means, uint8 is not padded to 32 bytes.
        */
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            /*
             Here we are loading the last 32 bytes. We exploit the fact that
             'mload' will pad with zeroes if we overread.
             There is no 'mload8' to do this, but that would be nicer.
            */
            v := byte(0, mload(add(_sig, 96)))
            /*
              Alternative solution:
              'byte' is not working due to the Solidity parser, so lets
              use the second best option, 'and'
              v := and(mload(add(_sig, 65)), 255)
            */
        }
        /*
         albeit non-transactional signatures are not specified by the YP, one would expect it
         to match the YP range of [27, 28]
         geth uses [0, 1] and some clients have followed. This might change, see:
         https://github.com/ethereum/go-ethereum/issues/2053
        */
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (false, address(0));
        }
        return safer_ecrecover(_hash, v, r, s);
    }

    function safeMemoryCleaner() internal pure {
        assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize(), sub(msize(), fmem))
        }
    }
}
// </provableAPI>


// File contracts/strings.sol

/*
 * Copyright 2016 Nick Johnson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

library strings {
    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    uint256 constant MAX_INT = 2**256 - 1;

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 mlen
    ) internal pure {
        // Copy word-length chunks while possible
        for (; mlen >= 32; mlen -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        if (mlen > 0) {
            uint256 mask = 256**(32 - mlen) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint256) {
        uint256 ret;
        if (self == 0) return 0;
        if (uint256(self) & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint256(self) / 0x100000000000000000000000000000000);
        }
        if (uint256(self) & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint256(self) / 0x10000000000000000);
        }
        if (uint256(self) & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint256(self) / 0x100000000);
        }
        if (uint256(self) & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint256(self) / 0x10000);
        }
        if (uint256(self) & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint256 l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint256 ptr = self._ptr - 31;
        uint256 end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other)
        internal
        pure
        returns (int256)
    {
        uint256 shortest = self._len;
        if (other._len < self._len) shortest = other._len;

        uint256 selfptr = self._ptr;
        uint256 otherptr = other._ptr;
        for (uint256 idx = 0; idx < shortest; idx += 32) {
            uint256 a;
            uint256 b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = uint256(MAX_INT); // 0xffff...
                if (shortest < 32) {
                    mask = ~(2**(8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0) return int256(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int256(self._len) - int256(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other)
        internal
        pure
        returns (bool)
    {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune)
        internal
        pure
        returns (slice memory)
    {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint256 l;
        uint256 b;
        // Load the first byte of the rune into the LSBs of b
        assembly {
            b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
        }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self)
        internal
        pure
        returns (slice memory ret)
    {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint256 ret) {
        if (self._len == 0) {
            return 0;
        }

        uint256 word;
        uint256 length;
        uint256 divisor = 2**248;

        // Load the rune into the MSBs of b
        assembly {
            word := mload(mload(add(self, 32)))
        }
        uint256 b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint256 i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle)
        internal
        pure
        returns (bool)
    {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle)
        internal
        pure
        returns (bool)
    {
        if (self._len < needle._len) {
            return false;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        if (self._len < needle._len) {
            return self;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint256 end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr) return selfptr;
                    ptr--;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory token)
    {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory token)
    {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle)
        internal
        pure
        returns (uint256 cnt)
    {
        uint256 ptr =
            findPtr(self._len, self._ptr, needle._len, needle._ptr) +
                needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr =
                findPtr(
                    self._len - (ptr - self._ptr),
                    ptr,
                    needle._len,
                    needle._ptr
                ) +
                needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle)
        internal
        pure
        returns (bool)
    {
        return
            rfindPtr(self._len, self._ptr, needle._len, needle._ptr) !=
            self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other)
        internal
        pure
        returns (string memory)
    {
        string memory ret = new string(self._len + other._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts)
        internal
        pure
        returns (string memory)
    {
        if (parts.length == 0) return '';

        uint256 length = self._len * (parts.length - 1);
        for (uint256 i = 0; i < parts.length; i++) {
            length += parts[i]._len;
        }

        string memory ret = new string(length);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        for (uint256 i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}


// File contracts/utils.sol

library Utils {
    function safeParseInt(string memory _a)
        internal
        pure
        returns (uint256 _parsedInt)
    {
        return safeParseInt(_a, 0);
    }

    function safeParseInt(string memory _a, uint256 _b)
        internal
        pure
        returns (uint256 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint256 mint = 0;
        bool decimals = false;
        for (uint256 i = 0; i < bresult.length; i++) {
            if (
                (uint256(uint8(bresult[i])) >= 48) &&
                (uint256(uint8(bresult[i])) <= 57)
            ) {
                if (decimals) {
                    if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint256(uint8(bresult[i])) - 48;
            } else if (uint256(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal in string');
                decimals = true;
            } else {
                revert('Non-numeral character in string');
            }
        }
        if (_b > 0) {
            mint *= 10**_b;
        }
        return mint;
    }
}


// File contracts/Wayback.sol

struct Snapshot {
    string cid; // IPFS content ID
    uint64 timestamp; // epoch at creation
    bytes proofCID; // Provable Android proof binary CIDv0
}

contract Wayback is usingProvable {
    using strings for *;

    address payable public owner;
    string public constant DOCKERFILE_CID =
        'QmRcSpugDv7eRWH57BDbJoPcuquEvPe8JUKeH6PFaKoKgc';
    // maximum Provable 'computation' output size (2500) minus some wiggle room
    uint16 public constant MAX_URL_LEN = 2410;
    mapping(bytes32 => bool) internal queryPending;
    mapping(string => Snapshot[]) internal snapshots;
    event SnapshotCreated(
        string url,
        string cid,
        uint64 timestamp,
        bytes proof
    );
    event SnapshotError(string url, string message);

    modifier onlyOwner {
        require(msg.sender == owner, 'Function only callable by owner');
        _;
    }

    constructor() payable {
        owner = payable(msg.sender);
        OAR = OracleAddrResolverI(0xC65cCB966873969179B6b0bA53D67D14Bbf1204C);
        provable_setProof(proofType_Android | proofStorage_IPFS);
    }

    function finalize() external onlyOwner {
        selfdestruct(owner);
    }

    function __callback(
        bytes32 queryID,
        string memory result,
        bytes memory proof
    ) public override {
        require(
            msg.sender == provable_cbAddress(),
            'Callback from wrong address'
        );
        require(queryPending[queryID], 'Query is not pending');
        delete queryPending[queryID];

        strings.slice memory r = result.toSlice();
        strings.slice memory sp = ' '.toSlice();

        uint8 status = uint8(Utils.safeParseInt(r.split(sp).toString()));

        string memory url = r.split(sp).toString();
        require(bytes(url).length > 0, 'Empty URL returned');

        if (handleCallbackErrors(status, url)) return;

        string memory cid = r.split(sp).toString();
        require(bytes(cid).length == 46, 'Invalid CID returned');

        uint64 timestamp = uint64(Utils.safeParseInt(r.split(sp).toString()));
        require(timestamp > 0, 'Invalid timestamp returned');

        require(proof.length == 34, 'Proof bytes have wrong size');

        snapshots[url].push(Snapshot(cid, timestamp, proof));
        emit SnapshotCreated(url, cid, timestamp, proof);
    }

    function handleCallbackErrors(uint8 status, string memory url)
        internal
        returns (bool)
    {
        if (status != 0) {
            if (status == 1) {
                emit SnapshotError(url, 'Could not resolve host');
            } else if (status == 2) {
                emit SnapshotError(url, 'Host timeout');
            } else if (status == 3) {
                emit SnapshotError(url, 'Unknown Error');
            } else if (status == 4) {
                emit SnapshotError(url, 'Infura service error');
            } else if (status == 5) {
                emit SnapshotError(url, 'Infura service response error');
            } else {
                emit SnapshotError(url, 'Unknown error');
            }
            return true;
        }
        return false;
    }

    function createSnapshot(string memory url) external payable {
        checkURL(url);
        // 260k base cost, 15k buffer, 280 per string byte
        uint256 gasLimit = 275000 + (280 * bytes(url).length);
        require(
            address(this).balance >= provable_getPrice('computation', gasLimit),
            'Insufficient funds'
        );
        bytes32 queryID =
            provable_query('computation', [DOCKERFILE_CID, url], gasLimit);
        queryPending[queryID] = true;
    }

    function checkURL(string memory url) internal pure {
        uint32 urlLen = uint32(bytes(url).length);
        require(urlLen > 0, 'URL must not be empty');
        require(urlLen <= MAX_URL_LEN, 'URL is too long');
    }

    function getSnapshots(string memory url)
        external
        view
        returns (
            string[] memory,
            uint64[] memory,
            bytes[] memory
        )
    {
        checkURL(url);
        uint32 numSnaps = uint32(snapshots[url].length);
        string[] memory cids = new string[](numSnaps);
        uint64[] memory timestamps = new uint64[](numSnaps);
        bytes[] memory proofCIDs = new bytes[](numSnaps);
        for (uint32 i = 0; i < numSnaps; i++) {
            Snapshot memory snapshot = snapshots[url][i];
            cids[i] = snapshot.cid;
            timestamps[i] = snapshot.timestamp;
            proofCIDs[i] = snapshot.proofCID;
        }
        return (cids, timestamps, proofCIDs);
    }
}