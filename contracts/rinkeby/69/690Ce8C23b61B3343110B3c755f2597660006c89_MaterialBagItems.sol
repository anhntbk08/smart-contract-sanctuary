// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// ============ Imports ============

import "./library/ERC1155.sol";
import "./library/IERC721.sol";
import "./library/Base64.sol";
import "./library/Strings.sol";
import "./library/MaterialTokenId.sol";
import "./library/MaterialComponents.sol";
import "./library/MaterialMetadata.sol";
import "./library/ItemMetadata.sol";


/// @title MaterialBagItems
/// @notice Allows "opening" your ERC721 Material Bags and extracting the items inside it
/// The created tokens are ERC1155 compatible, and their on-chain SVG is their name
contract MaterialBagItems is ERC1155, MaterialMetadata {

    //material bag contract (RINKEBY TEST NET)
    IERC721 materialBag = IERC721(0x6521dEBa0b1e61d626b7883aAC6B2A67f1f7e144);

    //for testing
    //IERC721 materialBag;

    constructor() ERC1155("") {
        //for testing
        //materialBag = IERC721(_materialBag);

        // FOR TESTING
        //dragonskin belt
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 196608, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 1441793, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 851970, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 1835011, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 327684, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 196613, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 393222, 1, "");

        //ancient helm
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 262144, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 983041, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 196610, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 2031619, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 65540, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 720901, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 327686, 1, "");

        //divine gloves
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 196608, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 2097153, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 851970, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 1638403, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 131076, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 720901, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 131078, 1, "");

        //ornate gauntlets
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 393216, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 655361, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 131074, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 3, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 393220, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 131077, 1, "");
        _mint(0x6404a754A05F0449AEFc4b1264b3B4a34Ab49Be7, 262150, 1, "");

    }

    /// @notice Transfers the erc721 bag from your account to the contract and then
    /// opens it. Use it if you have already approved the transfer, else consider
    /// just transferring directly to the contract and letting the `onERC721Received`
    /// do its part
    function open(uint256 tokenId) external {
        materialBag.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    /// @notice ERC721 callback which will open the bag
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        // only supports callback from the MaterialBag contract
        require(msg.sender == address(materialBag));
        open(from, tokenId);
        return MaterialBagItems.onERC721Received.selector;
    }

    /// @notice Opens your Material Bag and mints you 8 ERC-1155 tokens for each material
    /// in that bag
    function open(address who, uint256 tokenId) private {
        // NB: We patched ERC1155 to expose `_balances` so
        // that we can manually vb  to a user, and manually emit a `TransferBatch`
        // event. If that's unsafe, we can fallback to using _mint
        uint256[] memory tokenIds = new uint256[](8);
        uint256[] memory amounts = new uint256[](8);
        tokenIds[0] = itemId(tokenId, MaterialComponents.gemComponents, MaterialMetadata.GEMS);
        tokenIds[1] = itemId(tokenId, MaterialComponents.runeComponents, MaterialMetadata.RUNES);
        tokenIds[2] = itemId(tokenId, MaterialComponents.materialComponents, MaterialMetadata.MATERIALS);
        tokenIds[3] = itemId(tokenId, MaterialComponents.charmComponents, MaterialMetadata.CHARMS);
        tokenIds[4] = itemId(tokenId, MaterialComponents.toolComponents, MaterialMetadata.TOOLS);
        tokenIds[5] = itemId(tokenId, MaterialComponents.elementComponents, MaterialMetadata.ELEMENTS);
        tokenIds[6] = itemId(tokenId, MaterialComponents.requirementComponents, MaterialMetadata.REQUIREMENTS);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            amounts[i] = 1;
            // +21k per call / unavoidable - requires patching OZ
            _balances[tokenIds[i]][who] += 1; //minting the materials
        }

        emit TransferBatch(_msgSender(), address(0), who, tokenIds, amounts);
    }

    /// @notice Re-assembles the original Material Bag by burning all the ERC1155 tokens
    /// which were inside of it.  
    function reassemble(uint256 tokenId) external {
        // 1. burn the items
        burnItem(tokenId, MaterialComponents.gemComponents, MaterialMetadata.GEMS);
        burnItem(tokenId, MaterialComponents.runeComponents, MaterialMetadata.RUNES);
        burnItem(tokenId, MaterialComponents.materialComponents, MaterialMetadata.MATERIALS);
        burnItem(tokenId, MaterialComponents.charmComponents, MaterialMetadata.CHARMS);
        burnItem(tokenId, MaterialComponents.toolComponents, MaterialMetadata.TOOLS);
        burnItem(tokenId, MaterialComponents.elementComponents, MaterialMetadata.ELEMENTS);
        burnItem(tokenId, MaterialComponents.requirementComponents, MaterialMetadata.REQUIREMENTS);

        // 2. give back the bag
        materialBag.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /// @notice Extracts the components associated with the ERC721 Material bag using
    /// components for each material and proceeds to burn a token for the corresponding
    /// item from the msg.sender.
    function burnItem(
        uint256 tokenId,
        function(uint256) view returns (uint256[1] memory) componentsFn,
        uint256 itemType
    ) private {
        uint256[1] memory components = componentsFn(tokenId);
        uint256 id = MaterialTokenId.toId(components, itemType);
        _burn(msg.sender, id, 1);
    }

    function itemId(
        uint256 tokenId,
        function(uint256) view returns (uint256[1] memory) componentsFn,
        uint256 itemType
    ) private view returns (uint256) {
        uint256[1] memory components = componentsFn(tokenId);
        return MaterialTokenId.toId(components, itemType);
    }

    modifier tokenOwner(uint tokenId) {
        require(materialBag.ownerOf(tokenId) == msg.sender, "Not the owner of this token.");
        _;
    }

        // View helpers for getting the item ID that corresponds to a bag's items
    function seeGemId(uint256 tokenId) tokenOwner(tokenId) public view returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.gemComponents(tokenId), GEMS);
    }

    function seeRuneId(uint256 tokenId) tokenOwner(tokenId) public view returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.runeComponents(tokenId), RUNES);
    }

    function seeMaterialId(uint256 tokenId) tokenOwner(tokenId) public view returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.materialComponents(tokenId), MATERIALS);
    }

    function seeCharmId(uint256 tokenId) tokenOwner(tokenId) public view returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.charmComponents(tokenId), CHARMS);
    }

    function seeToolId(uint256 tokenId) tokenOwner(tokenId) public view returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.toolComponents(tokenId), TOOLS);
    }

    function seeElementId(uint256 tokenId) tokenOwner(tokenId) public view returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.elementComponents(tokenId), ELEMENTS);
    }

    function seeRequirementId(uint256 tokenId) tokenOwner(tokenId) public view returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.requirementComponents(tokenId), REQUIREMENTS);
    }

    function materialTrait(string memory _traitType, string memory _value) internal pure returns (string memory) {     
        return string(abi.encodePacked('{',
            '"trait_type": "', _traitType, '", ',
            '"value": "', _value, '"',
        '}'));
    }

    function materialAttributes(uint id) internal view returns (string memory) {
        (, uint256 itemType) = MaterialTokenId.fromId(id);
        string memory res;
        if (itemType == GEMS) {
            res = string(abi.encodePacked('[', materialTrait("Gem", MaterialMetadata.materialTokenName(id))));
        } else if (itemType == RUNES) {
            res = string(abi.encodePacked('[', materialTrait("Rune", MaterialMetadata.materialTokenName(id))));
        } else if (itemType == MATERIALS) {
            res = string(abi.encodePacked('[', materialTrait("Material", MaterialMetadata.materialTokenName(id))));
        } else if (itemType == CHARMS) {
            res = string(abi.encodePacked('[', materialTrait("Charm", MaterialMetadata.materialTokenName(id))));
        } else if (itemType == TOOLS) {
            res = string(abi.encodePacked('[', materialTrait("Tool", MaterialMetadata.materialTokenName(id))));
        } else if (itemType == ELEMENTS) {
            res = string(abi.encodePacked('[', materialTrait("Element", MaterialMetadata.materialTokenName(id))));
        } else if (itemType == REQUIREMENTS) {
            res = string(abi.encodePacked('[', materialTrait("Requirement", MaterialMetadata.materialTokenName(id))));
        }
        res = string(abi.encodePacked(res, ']'));

        return res;

    }

    /// @notice Returns an SVG for the provided 1155 token id
    function uri(uint256 tokenId) override public view returns (string memory) {
        string[3] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="50%" y="50%" class="base">';

        parts[1] = MaterialMetadata.materialTokenName(tokenId);

        parts[2] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Material Bag Item #', Strings.toString(tokenId), '", "description": "Material Bag Items lets you unbundle your Material Bags into individual ERC1155 NFTs or rebundle items into their original Material Bags.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)),'", ''"attributes": ', materialAttributes(tokenId),'}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) public _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


/*
TOKEN ID FOR MATERIALS

Library to generate tokenIDs for different components, based on token type and attributes. 

*/

library MaterialTokenId {
    // 2 bytes
    uint256 constant SHIFT = 16;

    /// Encodes an array of CrafterLodge components and an item type (gem, rune etc.)
    /// to a token id
    function toId(uint256[1] memory components, uint256 itemType)
        internal
        pure
        returns (uint256)
    {
        uint256 id = itemType;
        id += encode(components[0], 1);

        return id;
    }

    /// Decodes a token id to an array of CrafterLodge components and an item type (gem, rune etc.) 
    function fromId(uint256 id)
        internal
        pure
        returns (uint256[1] memory components, uint256 itemType)
    {
        itemType = decode(id, 0);
        components[0] = decode(id, 1);
    }

    /// Masks the component with 0xff and left shifts it by `idx * 2 bytes
    function encode(uint256 component, uint256 idx)
        private
        pure
        returns (uint256)
    {
        return (component & 0xff) << (SHIFT * idx);
    }

    /// Right shifts the provided token id by `idx * 2 bytes` and then masks the
    /// returned value with 0xff.
    function decode(uint256 id, uint256 idx) private pure returns (uint256) {
        return (id >> (SHIFT * idx)) & 0xff;
    }
}

// SPDX-License-Identifier: Unlicense

/*

    COMPONENTS
    
    Call gemComponents(), runeComponents(), etc. to get 
    an array of attributes that correspond to the item. 
    
    The return format is:
    
    uint256[1] =>
        [0] = Item ID


*/

pragma solidity ^0.8.4;

import "./Strings.sol";

contract MaterialComponents {
    //materials:
    string[] internal gems = [
        'Amethyst',
        'Topaz',
        'Sapphire',
        'Emerald',
        'Ruby',
        'Diamond',
        'Skull'
    ];

    uint256 constant gemsLength = 7;

    string[] internal runes = [	
        'El Rune',
        'Eld Rune',
        'Tir Rune',	
        'Nef Rune',	
        'Ith Rune',	
        'Tal Rune',	
        'Ral Rune',	
        'Ort Rune',	
        'Thul Rune',	
        'Amn Rune',	
        'Shael Rune',	
        'Dol Rune',	
        'Hel Rune',	
        'Io Rune',	
        'Lum Rune',	
        'Ko Rune',	
        'Fal Rune',	
        'Lem Rune',	
        'Pul Rune',	
        'Um Rune',	
        'Mal Rune',	
        'Ist Rune',	
        'Gul Rune',	
        'Vex Rune',	
        'Lo Rune',	
        'Sur Rune',	
        'Ber Rune',	
        'Jah Rune',	
        'Cham Rune',	
        'Zod Rune',	
        'Eth Rune',	
        'Sol Rune',	
        'Ohm Rune',	
        'Avax Rune',	
        'Fantom Rune',	
        'Dot Rune'	
    ];	

    uint256 constant runesLength = 35;

    string[] internal materials = [
        'Tin',
        'Iron',
        'Copper',
        'Bronze',
        'Silver',
        'Gold',
        'Leather Hide',
        'Silk',
        'Wool',
        'Obsidian',
        'Flametal',
        'Black Metal',
        'Dragon Skin',
        'Demon Hide',
        'Holy Water',
        'Force Crystals'
    ];

    uint256 constant materialsLength = 16;
    
    string[] internal charms = [
        'Arcing Charm',
        'Azure Charm',
        'Beryl Charm',
        'Bloody Charm',
        'Bronze Charm',
        'Burly Charm',
        'Burning Charm',
        'Chilling Charm',
        'Cobalt Charm',
        'Coral Charm',
        'Emerald Charm',
        'Entrapping Charm',
        'Fanatic Charm',
        'Fine Charm',
        'Forked Charm',
        'Foul Charm',
        'Hibernal Charm',
        'Iron Charm',
        'Jade Charm',
        'Lapis Charm',
        'Toxic Charm',
        'Amber Charm',
        'Boreal Charm',
        'Crimson Charm',
        'Ember Charm',
        'Ethereal Charm',
        'Flaming Charm',
        'Fungal Charm',
        'Garnet Charm',
        'Hexing Charm',
        'Jagged Charm',
        'Russet Charm',
        'Sanguinary Charm',
        'Tangerine Charm'
    ];

    uint256 constant charmsLength = 34;

    string[] internal tools = [
        'Anvil',
        'Fermenter',
        'Hanging Brazier',
        'Bronze Nails',
        'Adze',
        'Hammer',
        'Cultivator'
    ];

    uint256 constant toolsLength = 7;

    string[] internal elements = [		
        'Earth',		
        'Fire',		
        'Wind',		
        'Water',		
        'Mist',		
        'Shadow',		
        'Spirit',		
        'Power',		
        'Time',		
        'Infinity',		
        'Space',
        'Reality'		
    ];	

    uint256 constant elementsLength = 12;

    string[] internal requirements= [	
        'Strength',	
        'Intelligence',	
        'Wisdom',	
        'Dexterity',	
        'Constitution',	
        'Charisma',	
        'Mana'	
    ];

    uint256 constant requirementsLength = 7;

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function gemComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "GEM", gemsLength);
    }

    function runeComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "RUNE", runesLength);
    }

    function materialComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "MATERIAL", materialsLength);
    }

    function charmComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "CHARM", charmsLength);
    }

    function toolComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "TOOL", toolsLength);
    }

    function elementComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "ELEMENT", elementsLength);
    }

    function requirementComponents(uint256 tokenId)
        internal
        pure
        returns (uint256[1] memory)
    {
        return pluck(tokenId, "REQUIREMENT", requirementsLength);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        uint256 sourceArrayLength
    ) internal pure returns (uint256[1] memory) {
        uint256[1] memory components;

        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, Strings.toString(tokenId)))
        );

        components[0] = rand % sourceArrayLength;
        return components;
    }


}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./MaterialComponents.sol";
import "./MaterialTokenId.sol";
import "./Base64.sol";
import "./Strings.sol";

contract MaterialMetadata is MaterialComponents {

    uint256 internal constant GEMS = 0x0;
    uint256 internal constant RUNES = 0x1;
    uint256 internal constant MATERIALS = 0x2;
    uint256 internal constant CHARMS = 0x3;
    uint256 internal constant TOOLS = 0x4;
    uint256 internal constant ELEMENTS = 0x5;
    uint256 internal constant REQUIREMENTS = 0x6;

    //needed to generate itemIDS
    string[] internal materialItemTypes = [
        "Gem",
        "Rune",
        "Material",
        "Charm",
        "Tool",
        "Element",
        "Requirement"
    ];

    struct MaterialItemIds {
        uint256 gem;
        uint256 rune;
        uint256 material;
        uint256 charm;
        uint256 tool;
        uint256 element;
        uint256 requirement;
    }
    struct MaterialItemNames {
        string gem;
        string rune;
        string material;
        string charm;
        string tool;
        string element;
        string requirement;
    }

    /// @notice Given an ERC1155 token id, it returns its name by decoding and parsing
    /// the id
    function materialTokenName(uint256 id) public view returns (string memory) {
        (uint256[1] memory components, uint256 itemType) = MaterialTokenId.fromId(id);
        return materialItemName(itemType, components[0]);
    }

    // Returns the "vanilla" item name w/o any prefix/suffixes or augmentations
    function materialItemName(uint256 itemType, uint256 idx) private view returns (string memory) {
        string[] storage arr;
        if (itemType == GEMS) {
            arr = MaterialComponents.gems;
        } else if (itemType == RUNES) {
            arr = MaterialComponents.runes;
        } else if (itemType == MATERIALS) {
            arr = MaterialComponents.materials;
        } else if (itemType == CHARMS) {
            arr = MaterialComponents.charms;
        } else if (itemType == TOOLS) {
            arr = MaterialComponents.tools;
        } else if (itemType == ELEMENTS) {
            arr = MaterialComponents.elements;
        } else if (itemType == REQUIREMENTS) {
            arr = MaterialComponents.requirements;
        } else {
            revert("Unexpected material item");
        }

        return arr[idx];
    }

    // View helpers for getting the item ID that corresponds to a bag's items
    function gemId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.gemComponents(tokenId), GEMS);
    }

    function runeId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.runeComponents(tokenId), RUNES);
    }

    function materialId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.materialComponents(tokenId), MATERIALS);
    }

    function charmId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.charmComponents(tokenId), CHARMS);
    }

    function toolId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.toolComponents(tokenId), TOOLS);
    }

    function elementId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.elementComponents(tokenId), ELEMENTS);
    }

    function requirementId(uint256 tokenId) public pure returns (uint256) {
        return MaterialTokenId.toId(MaterialComponents.requirementComponents(tokenId), REQUIREMENTS);
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ItemComponents.sol";
import "./ItemTokenId.sol";
import "./Base64.sol";
import "./Strings.sol";

contract ItemMetadata is ItemComponents {

    uint256 internal constant WEAPON = 0x0;
    uint256 internal constant CHEST = 0x1;
    uint256 internal constant HEAD = 0x2;
    uint256 internal constant WAIST = 0x3;
    uint256 internal constant FOOT = 0x4;
    uint256 internal constant HAND = 0x5;
    uint256 internal constant NECK = 0x6;
    uint256 internal constant RING = 0x7;

    string[] internal itemTypes = [
        "Weapon",
        "Chest",
        "Head",
        "Waist",
        "Foot",
        "Hand",
        "Neck",
        "Ring"
    ];

    struct ItemIds {
        uint256 weapon;
        uint256 chest;
        uint256 head;
        uint256 waist;
        uint256 foot;
        uint256 hand;
        uint256 neck;
        uint256 ring;
    }
    struct ItemNames {
        string weapon;
        string chest;
        string head;
        string waist;
        string foot;
        string hand;
        string neck;
        string ring;
    }

    //rare materials

    // @notice Given an ERC1155 token id, it returns its name by decoding and parsing
    // the id
    function tokenName(uint256 id) public view returns (string memory) {
        (uint256[5] memory components, uint256 itemType) = ItemTokenId.fromId(id);
        return componentsToString(components, itemType);
    }

    // Returns the "vanilla" item name w/o any prefix/suffixes or augmentations
    function itemName(uint256 itemType, uint256 idx) public view returns (string memory) {
        string[] storage arr;
        if (itemType == WEAPON) {
            arr = weapons;
        } else if (itemType == CHEST) {
            arr = chestArmor;
        } else if (itemType == HEAD) {
            arr = headArmor;
        } else if (itemType == WAIST) {
            arr = waistArmor;
        } else if (itemType == FOOT) {
            arr = footArmor;
        } else if (itemType == HAND) {
            arr = handArmor;
        } else if (itemType == NECK) {
            arr = necklaces;
        } else if (itemType == RING) {
            arr = rings;
        } else {
            revert("Unexpected armor piece");
        }

        return arr[idx];
    }

    // Creates the token description given its components and what type it is
    function componentsToString(uint256[5] memory components, uint256 itemType)
        public
        view
        returns (string memory)
    {
        // item type: what slot to get
        // components[0] the index in the array
        string memory item = itemName(itemType, components[0]);

        // We need to do -1 because the 'no description' is not part of loot copmonents

        // add the suffix
        if (components[1] > 0) {
            item = string(
                abi.encodePacked(item, " ", ItemComponents.suffixes[components[1] - 1])
            );
        }

        // add the name prefix / suffix
        if (components[2] > 0) {
            // prefix
            string memory namePrefixSuffix = string(
                abi.encodePacked("'", ItemComponents.namePrefixes[components[2] - 1])
            );
            if (components[3] > 0) {
                namePrefixSuffix = string(
                    abi.encodePacked(namePrefixSuffix, " ", ItemComponents.nameSuffixes[components[3] - 1])
                );
            }

            namePrefixSuffix = string(abi.encodePacked(namePrefixSuffix, "' "));

            item = string(abi.encodePacked(namePrefixSuffix, item));
        }

        // add the augmentation
        if (components[4] > 0) {
            item = string(abi.encodePacked(item, " +1"));
        }

        return item;
    }

    // View helpers for getting the item ID that corresponds to a bag's items
    function weaponId(uint256 tokenId) public pure returns (uint256) {
        return ItemTokenId.toId(weaponComponents(tokenId), WEAPON);
    }

    function chestId(uint256 tokenId) public pure returns (uint256) {
        return ItemTokenId.toId(chestComponents(tokenId), CHEST);
    }

    function headId(uint256 tokenId) public pure returns (uint256) {
        return ItemTokenId.toId(headComponents(tokenId), HEAD);
    }

    function waistId(uint256 tokenId) public pure returns (uint256) {
        return ItemTokenId.toId(waistComponents(tokenId), WAIST);
    }

    function footId(uint256 tokenId) public pure returns (uint256) {
        return ItemTokenId.toId(footComponents(tokenId), FOOT);
    }

    function handId(uint256 tokenId) public pure returns (uint256) {
        return ItemTokenId.toId(handComponents(tokenId), HAND);
    }

    function neckId(uint256 tokenId) public pure returns (uint256) {
        return ItemTokenId.toId(neckComponents(tokenId), NECK);
    }

    function ringId(uint256 tokenId) public pure returns (uint256) {
        return ItemTokenId.toId(ringComponents(tokenId), RING);
    }

    // Given an erc721 bag, returns the erc1155 token ids of the items in the bag
    function ids(uint256 tokenId) public pure returns (ItemIds memory) {
        return
            ItemIds({
                weapon: weaponId(tokenId),
                chest: chestId(tokenId),
                head: headId(tokenId),
                waist: waistId(tokenId),
                foot: footId(tokenId),
                hand: handId(tokenId),
                neck: neckId(tokenId),
                ring: ringId(tokenId)
            });
    }

    // Given an ERC721 bag, returns the names of the items in the bag
    function seeItems(uint256 tokenId) public view returns (ItemNames memory) {
        ItemIds memory items = ids(tokenId);
        return
            ItemNames({
                weapon: tokenName(items.weapon),
                chest: tokenName(items.chest),
                head: tokenName(items.head),
                waist: tokenName(items.waist),
                foot: tokenName(items.foot),
                hand: tokenName(items.hand),
                neck: tokenName(items.neck),
                ring: tokenName(items.ring)
            });
    }
        /// @notice Returns the attributes associated with this item.
    /// @dev Opensea Standards: https://docs.opensea.io/docs/metadata-standards
    function attributes(uint256 id) public view returns (string memory) {
        (uint256[5] memory components, uint256 itemType) = ItemTokenId.fromId(id);
        // should we also use components[0] which contains the item name?
        string memory slot = itemTypes[itemType];
        string memory res = string(abi.encodePacked('[', trait("Slot", slot)));

        string memory item = itemName(itemType, components[0]);
        res = string(abi.encodePacked(res, ", ", trait("Item", item)));

        if (components[1] > 0) {
            string memory data = suffixes[components[1] - 1];
            res = string(abi.encodePacked(res, ", ", trait("Suffix", data)));
        }

        if (components[2] > 0) {
            string memory data = namePrefixes[components[2] - 1];
            res = string(abi.encodePacked(res, ", ", trait("Name Prefix", data)));
        }

        if (components[3] > 0) {
            string memory data = nameSuffixes[components[3] - 1];
            res = string(abi.encodePacked(res, ", ", trait("Name Suffix", data)));
        }

        if (components[4] > 0) {
            res = string(abi.encodePacked(res, ", ", trait("Augmentation", "Yes")));
        }

        res = string(abi.encodePacked(res, ']'));

        return res;
    }

    // Helper for encoding as json w/ trait_type / value from opensea
    function trait(string memory _traitType, string memory _value) internal pure returns (string memory) {
        return string(abi.encodePacked('{',
            '"trait_type": "', _traitType, '", ',
            '"value": "', _value, '"',
        '}'));
      }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

/**
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
        return msg.data;
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

// SPDX-License-Identifier: Unlicense

/*

    Components.sol
    
    This is a utility contract to make it easier for other
    contracts to work with Loot properties.
    
    Call weaponComponents(), chestComponents(), etc. to get 
    an array of attributes that correspond to the item. 
    
    The return format is:
    
    uint256[5] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)
    
    See the item and attribute tables below for corresponding IDs.

*/

pragma solidity ^0.8.4;

import "./Strings.sol";

contract ItemComponents {

    //items:
    string[] internal weapons = [
        "Warhammer", // 0
        "Quarterstaff", // 1
        "Maul", // 2
        "Mace", // 3
        "Club", // 4
        "Katana", // 5
        "Falchion", // 6
        "Scimitar", // 7
        "Long Sword", // 8
        "Short Sword", // 9
        "Ghost Wand", // 10
        "Grave Wand", // 11
        "Bone Wand", // 12
        "Wand", // 13
        "Grimoire", // 14
        "Chronicle", // 15
        "Tome", // 16
        "Book" // 17
    ];
    uint256 constant weaponsLength = 18;

    string[] internal chestArmor = [
        "Divine Robe", // 0
        "Silk Robe", // 1
        "Linen Robe", // 2
        "Robe", // 3
        "Shirt", // 4
        "Demon Husk", // 5
        "Dragonskin Armor", // 6
        "Studded Leather Armor", // 7
        "Hard Leather Armor", // 8
        "Leather Armor", // 9
        "Holy Chestplate", // 10
        "Ornate Chestplate", // 11
        "Plate Mail", // 12
        "Chain Mail", // 13
        "Ring Mail" // 14
    ];
    uint256 constant chestLength = 15;

    string[] internal headArmor = [
        "Ancient Helm", // 0
        "Ornate Helm", // 1
        "Great Helm", // 2
        "Full Helm", // 3
        "Helm", // 4
        "Demon Crown", // 5
        "Dragon's Crown", // 6
        "War Cap", // 7
        "Leather Cap", // 8
        "Cap", // 9
        "Crown", // 10
        "Divine Hood", // 11
        "Silk Hood", // 12
        "Linen Hood", // 13
        "Hood" // 14
    ];
    uint256 constant headLength = 15;

    string[] internal waistArmor = [
        "Ornate Belt", // 0
        "War Belt", // 1
        "Plated Belt", // 2
        "Mesh Belt", // 3
        "Heavy Belt", // 4
        "Demonhide Belt", // 5
        "Dragonskin Belt", // 6
        "Studded Leather Belt", // 7
        "Hard Leather Belt", // 8
        "Leather Belt", // 9
        "Brightsilk Sash", // 10
        "Silk Sash", // 11
        "Wool Sash", // 12
        "Linen Sash", // 13
        "Sash" // 14
    ];
    uint256 constant waistLength = 15;

    string[] internal footArmor = [
        "Holy Greaves", // 0
        "Ornate Greaves", // 1
        "Greaves", // 2
        "Chain Boots", // 3
        "Heavy Boots", // 4
        "Demonhide Boots", // 5
        "Dragonskin Boots", // 6
        "Studded Leather Boots", // 7
        "Hard Leather Boots", // 8
        "Leather Boots", // 9
        "Divine Slippers", // 10
        "Silk Slippers", // 11
        "Wool Shoes", // 12
        "Linen Shoes", // 13
        "Shoes" // 14
    ];
    uint256 constant footLength = 15;

    string[] internal handArmor = [
        "Holy Gauntlets", // 0
        "Ornate Gauntlets", // 1
        "Gauntlets", // 2
        "Chain Gloves", // 3
        "Heavy Gloves", // 4
        "Demon's Hands", // 5
        "Dragonskin Gloves", // 6
        "Studded Leather Gloves", // 7
        "Hard Leather Gloves", // 8
        "Leather Gloves", // 9
        "Divine Gloves", // 10
        "Silk Gloves", // 11
        "Wool Gloves", // 12
        "Linen Gloves", // 13
        "Gloves" // 14
    ];
    uint256 constant handLength = 15;

    string[] internal necklaces = [
        "Necklace", // 0
        "Amulet", // 1
        "Pendant" // 2
    ];
    uint256 constant necklacesLength = 3;

    string[] internal rings = [
        "Gold Ring", // 0
        "Silver Ring", // 1
        "Bronze Ring", // 2
        "Platinum Ring", // 3
        "Titanium Ring" // 4
    ];
    uint256 constant ringsLength = 5;
    
    string[] internal suffixes = [
        "of Power",
        "of Giants",
        "of Titans",
        "of Skill",
        "of Perfection",
        "of Brilliance",
        "of Enlightenment",
        "of Protection",
        "of Anger",
        "of Rage",
        "of Fury",
        "of Vitriol",
        "of the Fox",
        "of Detection",
        "of Reflection",
        "of the Twins"
    ];
    
    string[] internal namePrefixes = [
        "Agony", "Apocalypse", "Armageddon", "Beast", "Behemoth", "Blight", "Blood", "Bramble", 
        "Brimstone", "Brood", "Carrion", "Cataclysm", "Chimeric", "Corpse", "Corruption", "Damnation", 
        "Death", "Demon", "Dire", "Dragon", "Dread", "Doom", "Dusk", "Eagle", "Empyrean", "Fate", "Foe", 
        "Gale", "Ghoul", "Gloom", "Glyph", "Golem", "Grim", "Hate", "Havoc", "Honour", "Horror", "Hypnotic", 
        "Kraken", "Loath", "Maelstrom", "Mind", "Miracle", "Morbid", "Oblivion", "Onslaught", "Pain", 
        "Pandemonium", "Phoenix", "Plague", "Rage", "Rapture", "Rune", "Skull", "Sol", "Soul", "Sorrow", 
        "Spirit", "Storm", "Tempest", "Torment", "Vengeance", "Victory", "Viper", "Vortex", "Woe", "Wrath",
        "Light's", "Shimmering"  
    ];
    
    string[] internal nameSuffixes = [
        "Bane",
        "Root",
        "Bite",
        "Song",
        "Roar",
        "Grasp",
        "Instrument",
        "Glow",
        "Bender",
        "Shadow",
        "Whisper",
        "Shout",
        "Growl",
        "Tear",
        "Peak",
        "Form",
        "Sun",
        "Moon"
    ];

    uint256 constant suffixesLength = 16;

    uint256 constant namePrefixesLength = 69;

    uint256 constant nameSuffixesLength = 18;

    function itemRandom(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function weaponComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "WEAPON", weaponsLength);
    }

    function chestComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "CHEST", chestLength);
    }

    function headComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "HEAD", headLength);
    }

    function waistComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "WAIST", waistLength);
    }

    function footComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "FOOT", footLength);
    }

    function handComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "HAND", handLength);
    }

    function neckComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "NECK", necklacesLength);
    }

    function ringComponents(uint256 tokenId)
        public
        pure
        returns (uint256[5] memory)
    {
        return itemPluck(tokenId, "RING", ringsLength);
    }

    function itemPluck(
        uint256 tokenId,
        string memory keyPrefix,
        uint256 sourceArrayLength
    ) public pure returns (uint256[5] memory) {
        uint256[5] memory components;

        uint256 rand = itemRandom(
            string(abi.encodePacked(keyPrefix, Strings.toString(tokenId)))
        );

        components[0] = rand % sourceArrayLength;
        components[1] = 0;
        components[2] = 0;

        uint256 greatness = rand % 21;
        if (greatness > 14) {
            components[1] = (rand % suffixesLength) + 1;
        }
        if (greatness >= 19) {
            components[2] = (rand % namePrefixesLength) + 1;
            components[3] = (rand % nameSuffixesLength) + 1;
            if (greatness == 19) {
                // ...
            } else {
                components[4] = 1;
            }
        }

        return components;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;



library ItemTokenId {
    // 2 bytes
    uint256 constant SHIFT = 16;

    /// Encodes an array of Loot components and an item type (weapon, chest etc.)
    /// to a token id
    function toId(uint256[5] memory components, uint256 itemType)
        internal
        pure
        returns (uint256)
    {
        uint256 id = itemType;
        id += encode(components[0], 1);
        id += encode(components[1], 2);
        id += encode(components[2], 3);
        id += encode(components[3], 4);
        id += encode(components[4], 5);

        return id;
    }

    /// Decodes a token id to an array of Loot components and its item type (weapon, chest etc.)
    function fromId(uint256 id)
        internal
        pure
        returns (uint256[5] memory components, uint256 itemType)
    {
        itemType = decode(id, 0);
        components[0] = decode(id, 1);
        components[1] = decode(id, 2);
        components[2] = decode(id, 3);
        components[3] = decode(id, 4);
        components[4] = decode(id, 5);
    }

    /// Masks the component with 0xff and left shifts it by `idx * 2 bytes
    function encode(uint256 component, uint256 idx)
        private
        pure
        returns (uint256)
    {
        return (component & 0xff) << (SHIFT * idx);
    }

    /// Right shifts the provided token id by `idx * 2 bytes` and then masks the
    /// returned value with 0xff.
    function decode(uint256 id, uint256 idx) private pure returns (uint256) {
        return (id >> (SHIFT * idx)) & 0xff;
    }
}