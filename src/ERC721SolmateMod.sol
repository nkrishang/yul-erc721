// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice  This contract is a reference ERC-721 with a test case (but without use of inline assembly). The purpose
///          of the contract is to contrast it with a Yul ERC-721 implementation that passes the same tests.
///
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC721.sol)
///
/// @dev Note: WARNING! This mock is strictly intended for testing purposes only.
///
///        This is Solmate's ERC-721 modified to work with Solady ERC721 test cases. It does not include
///        auxData or extraData, or any significant designs from the Solady implementation. The contract
///        may contain redundancies.
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

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

        address caller = msg.sender;
        if(caller != owner && !isApprovedForAll[owner][caller] && caller != getApproved[id]) {
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

        if (from != owner) {
            revert TransferFromIncorrectOwner();
        }

        if (to == address(0)) {
            revert TransferToZeroAddress();
        }

        if(msg.sender != owner && !isApprovedForAll[owner][msg.sender] && msg.sender != getApproved[id]) {
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
        safeTransferFrom(from, to, id, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public payable virtual {
        transferFrom(from, to, id);
        _safeTransferCheck(msg.sender, from, to, id, data);
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
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    // function mint(address to, uint256 id) public payable {
    //     if (to == address(0)) {
    //         revert TransferToZeroAddress();
    //     }

    //     if(_ownerOf[id] != address(0)) {
    //         revert TokenAlreadyExists();
    //     }

    //     // Counter overflow is incredibly unrealistic.
    //     unchecked {
    //         _balanceOf[to]++;
    //     }

    //     _ownerOf[id] = to;

    //     emit Transfer(address(0), to, id);
    // }

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }

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

        if(owner == address(0)) {
            revert TokenDoesNotExist();
        }

        address caller = msg.sender;
        if(caller != owner && !isApprovedForAll[owner][caller] && caller != getApproved[id]) {
            revert NotOwnerNorApproved();
        }

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);
        _safeTransferCheck(msg.sender, address(0), to, id, data);
    }

    function _safeTransferCheck(address operator, address from, address to, uint256 id, bytes memory data) internal {
        if (to.code.length > 0) {

            (bool success, bytes memory retData) = to.call(abi.encodeWithSelector(
                ERC721TokenReceiver.onERC721Received.selector,
                operator, from, id, data
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