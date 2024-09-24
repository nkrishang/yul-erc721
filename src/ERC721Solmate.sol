// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Only the token owner or an approved account can manage the token.
    error NotOwnerNorApproved();

    /// @dev The token does not exist.
    error TokenDoesNotExist();

    /// @dev The token already exists.
    error TokenAlreadyExists();

    /// @dev Cannot query the balance for the zero address.
    error BalanceQueryForZeroAddress();

    /// @dev Cannot mint or transfer to the zero address.
    error TransferToZeroAddress();

    /// @dev The token must be owned by `from`.
    error TransferFromIncorrectOwner();

    /// @dev Cannot safely transfer to a contract that does not implement
    /// the ERC721Receiver interface.
    error TransferToNonERC721ReceiverImplementer();

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        owner = _ownerOf[id];
        if(owner == address(0)) {
            revert TokenDoesNotExist();
        }
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        // require(owner != address(0), "ZERO_ADDRESS");
        if (owner == address(0)) {
            revert BalanceQueryForZeroAddress();
        }

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public payable virtual {
        address owner = _ownerOf[id];
        if(owner == address(0)) {
            revert TokenDoesNotExist();
        }

        // require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");
        if(!_isApprovedOrOwner(msg.sender, id)) {
            revert NotOwnerNorApproved();
        }

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public payable virtual {
        address owner = _ownerOf[id];

        if(owner == address(0)) {
            revert TokenDoesNotExist();
        }

        // require(from == _ownerOf[id], "WRONG_FROM");
        if (from != owner) {
            revert TransferFromIncorrectOwner();
        }

        // require(to != address(0), "INVALID_RECIPIENT");
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }

        // require(
        //     msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
        //     "NOT_AUTHORIZED"
        // );
        if (!_isApprovedOrOwner(msg.sender, id)) {
            revert NotOwnerNorApproved();
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public payable virtual {
        transferFrom(from, to, id);

        // require(
        //     to.code.length == 0 ||
        //         ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
        //         ERC721TokenReceiver.onERC721Received.selector,
        //     "UNSAFE_RECIPIENT"
        // );

        if (to.code.length > 0) {


            (bool success, bytes memory retData) = to.call(abi.encodeWithSelector(
                ERC721TokenReceiver.onERC721Received.selector,
                msg.sender, from, id, ""
            ));

            if(success) {
                bytes4 sel = abi.decode(retData, (bytes4));
                if (sel != ERC721TokenReceiver.onERC721Received.selector) {
                    revert TransferToNonERC721ReceiverImplementer();
                } 
            } else {
                if (retData.length > 0) {
                    (, bytes memory reason) = address(this).call(retData);
                    revert(abi.decode(reason, (string)));
                }

                revert TransferToNonERC721ReceiverImplementer();
            }
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public payable virtual {
        transferFrom(from, to, id);

        // require(
        //     to.code.length == 0 ||
        //         ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
        //         ERC721TokenReceiver.onERC721Received.selector,
        //     "UNSAFE_RECIPIENT"
        // );

        if (to.code.length > 0) {


            (bool success, bytes memory retData) = to.call(abi.encodeWithSelector(
                ERC721TokenReceiver.onERC721Received.selector,
                msg.sender, from, id, data
            ));

            if(success) {
                bytes4 sel = abi.decode(retData, (bytes4));
                if (sel != ERC721TokenReceiver.onERC721Received.selector) {
                    revert TransferToNonERC721ReceiverImplementer();
                } 
            } else {
                if (retData.length > 0) {
                    (, bytes memory reason) = address(this).call(retData);
                    revert(abi.decode(reason, (string)));
                }

                revert TransferToNonERC721ReceiverImplementer();
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN/APPROVE LOGIC
    //////////////////////////////////////////////////////////////*/

    function _approve(address spender, uint256 id) internal virtual {
        address owner = _ownerOf[id];
        if(owner == address(0)) {
            revert TokenDoesNotExist();
        }

        // require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");
        if (!_isApprovedOrOwner(msg.sender, id)) {
            revert NotOwnerNorApproved();
        }

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        isApprovedForAll[owner][operator] = approved;

        emit ApprovalForAll(owner, operator, approved);
    }

    function _transfer(address operator, address from, address to, uint256 id) internal virtual {
        address owner = _ownerOf[id];

        if(owner == address(0)) {
            revert TokenDoesNotExist();
        }

        // require(from == _ownerOf[id], "WRONG_FROM");
        if (from != owner) {
            revert TransferFromIncorrectOwner();
        }

        // require(to != address(0), "INVALID_RECIPIENT");
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }

        // require(
        //     operator == from || isApprovedForAll[from][operator] || operator == getApproved[id],
        //     "NOT_AUTHORIZED"
        // );
        if (!_isApprovedOrOwner(operator, id)) {
            revert NotOwnerNorApproved();
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function _safeTransfer(address operator, address from, address to, uint256 id) internal virtual {
        _safeTransfer(operator, from, to, id, "");
    }

    function _safeTransfer(address operator, address from, address to, uint256 id, bytes memory data) internal virtual {
        _transfer(operator, from, to, id);

        // require(
        //     to.code.length == 0 ||
        //         ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
        //         ERC721TokenReceiver.onERC721Received.selector,
        //     "UNSAFE_RECIPIENT"
        // );

        if (to.code.length > 0) {


            (bool success, bytes memory retData) = to.call(abi.encodeWithSelector(
                ERC721TokenReceiver.onERC721Received.selector,
                msg.sender, from, id, data
            ));

            if(success) {
                bytes4 sel = abi.decode(retData, (bytes4));
                if (sel != ERC721TokenReceiver.onERC721Received.selector) {
                    revert TransferToNonERC721ReceiverImplementer();
                } 
            } else {
                if (retData.length > 0) {
                    (, bytes memory reason) = address(this).call(retData);
                    revert(abi.decode(reason, (string)));
                }

                revert TransferToNonERC721ReceiverImplementer();
            }
        }
    }

    function _mint(address to, uint256 id) internal virtual {
        // require(to != address(0), "INVALID_RECIPIENT");
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }

        // require(_ownerOf[id] == address(0), "ALREADY_MINTED");
        if(_ownerOf[id] != address(0)) {
            revert TokenAlreadyExists();
        }

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        // require(owner != address(0), "NOT_MINTED");
        if(owner == address(0)) {
            revert TokenDoesNotExist();
        }

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    function _isApprovedOrOwner(address target, uint256 id) internal view returns (bool) {
        address owner = _ownerOf[id];
        return target == owner || isApprovedForAll[owner][target] || target == getApproved[id];
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _safeMint(to, id, "");
    }

    event BytesData(bytes data);
    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        // require(
        //     to.code.length == 0 ||
        //         ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
        //         ERC721TokenReceiver.onERC721Received.selector,
        //     "UNSAFE_RECIPIENT"
        // );

        if (to.code.length > 0) {

            (bool success, bytes memory retData) = to.call(abi.encodeWithSelector(
                ERC721TokenReceiver.onERC721Received.selector,
                msg.sender, address(0), id, data
            ));

            if(success) {
                bytes4 sel = abi.decode(retData, (bytes4));
                if (sel != ERC721TokenReceiver.onERC721Received.selector) {
                    revert TransferToNonERC721ReceiverImplementer();
                } 
            } else {
                if (retData.length > 0) {
                    (, bytes memory reason) = address(this).call(retData);
                    revert(abi.decode(reason, (string)));
                }

                revert TransferToNonERC721ReceiverImplementer();
            }


            // try ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) returns (bytes4 sel) {
            //     if (sel != ERC721TokenReceiver.onERC721Received.selector) {
            //         revert TransferToNonERC721ReceiverImplementer();
            //     } 
            // } catch Error(string memory reason) {
            //     revert(reason);
            // }
        }
    }

    function Error(string memory text) public pure returns(string memory) {
        return text;
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}