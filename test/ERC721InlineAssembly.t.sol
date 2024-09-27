// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MockERC721InlineAssembly} from "./mock/MockERC721InlineAssembly.sol";

abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract ERC721Recipient is ERC721TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(address _operator, address _from, uint256 _id, bytes calldata _data)
        public
        virtual
        override
        returns (bytes4)
    {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract RevertingERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        public
        virtual
        override
        returns (bytes4)
    {
        revert(string(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector)));
    }
}

contract WrongReturnDataERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        public
        virtual
        override
        returns (bytes4)
    {
        return 0xCAFEBEEF;
    }
}

contract NonERC721Recipient {}

contract ERC721InlineAssemblyTest is SoladyTest {
    MockERC721InlineAssembly token;

    uint256 private constant _ERC721_MASTER_SLOT_SEED = 0x7d8825530a5a2e7a << 192;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed approved, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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

    /// @dev The recipient's balance has overflowed.
    error AccountBalanceOverflow();

    /// @dev Cannot safely transfer to a contract that does not implement
    /// the ERC721Receiver interface.
    error TransferToNonERC721ReceiverImplementer();

    function setUp() public {
        token = new MockERC721InlineAssembly();
    }

    function _expectMintEvent(address to, uint256 id) internal {
        _expectTransferEvent(address(0), to, id);
    }

    function _expectBurnEvent(address from, uint256 id) internal {
        _expectTransferEvent(from, address(0), id);
    }

    function _expectTransferEvent(address from, address to, uint256 id) internal {
        vm.expectEmit(true, true, true, true);
        emit Transfer(_cleaned(from), _cleaned(to), id);
    }

    function _expectApprovalEvent(address owner, address approved, uint256 id) internal {
        vm.expectEmit(true, true, true, true);
        emit Approval(_cleaned(owner), _cleaned(approved), id);
    }

    function _expectApprovalForAllEvent(address owner, address operator, bool approved) internal {
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(_cleaned(owner), _cleaned(operator), approved);
    }

    function _transferFrom(address caller, address from, address to, uint256 id) internal {
        if (_randomChance(2)) {
            vm.prank(caller);
            token.transferFrom(from, to, id);
        } else {
            vm.prank(_brutalized(caller));
            token.transferFrom(from, to, id);
        }
    }

    function _safeTransferFrom(address caller, address from, address to, uint256 id) internal {
        if (_randomChance(2)) {
            vm.prank(caller);
            token.safeTransferFrom(from, to, id);
        } else {
            vm.prank(_brutalized(caller));
            token.safeTransferFrom(from, to, id);
        }
    }

    function _safeTransferFrom(address caller, address from, address to, uint256 id, bytes memory data) internal {
        if (_randomChance(2)) {
            vm.prank(caller);
            token.safeTransferFrom(from, to, id, data);
        } else {
            vm.prank(_brutalized(caller));
            token.safeTransferFrom(from, to, id, data);
        }
    }

    function _approve(address caller, address spender, uint256 id) internal {
        if (_randomChance(2)) {
            vm.prank(caller);
            token.approve(spender, id);
        } else {
            vm.prank(_brutalized(caller));
            token.approve(spender, id);
        }
    }

    function _setApprovalForAll(address caller, address operator, bool approved) internal {
        if (_randomChance(2)) {
            vm.prank(caller);
            token.setApprovalForAll(operator, approved);
        } else {
            vm.prank(_brutalized(caller));
            token.setApprovalForAll(operator, approved);
        }
    }

    function _ownerOf(uint256 id) internal view returns (address) {
        return token.ownerOf(id);
    }

    function _getApproved(uint256 id) internal view returns (address) {
        return token.getApproved(id);
    }

    function _owners() internal returns (address a, address b) {
        a = _randomNonZeroAddress();
        b = _randomNonZeroAddress();
        while (a == b) b = _randomNonZeroAddress();
    }

    function testSafetyOfCustomStorage(uint256 id0, uint256 id1) public {
        bool safe;
        while (id0 == id1) id1 = _random();
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, id0)
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            let slot0 := add(id0, add(id0, keccak256(0x00, 0x20)))
            let slot2 := add(1, slot0)
            mstore(0x00, id1)
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            let slot1 := add(id1, add(id1, keccak256(0x00, 0x20)))
            let slot3 := add(1, slot1)
            safe := 1
            if eq(slot0, slot1) { safe := 0 }
            if eq(slot0, slot2) { safe := 0 }
            if eq(slot0, slot3) { safe := 0 }
            if eq(slot1, slot2) { safe := 0 }
            if eq(slot1, slot3) { safe := 0 }
            if eq(slot2, slot3) { safe := 0 }
        }
        require(safe, "Custom storage not safe");
    }

    function testAuthorizedEquivalence(address by, bool isOwnerOrOperator, bool isApprovedAccount)
        public
        pure
    {
        bool a = true;
        bool b = true;
        /// @solidity memory-safe-assembly
        assembly {
            if by { if iszero(isOwnerOrOperator) { a := isApprovedAccount } }
            if iszero(or(iszero(by), isOwnerOrOperator)) { b := isApprovedAccount }
        }
        assertEq(a, b);
    }

    function testMint(uint256 id) public {
        address owner = _randomNonZeroAddress();

        _expectMintEvent(owner, id);
        token.mint(owner, id);

        assertEq(token.balanceOf(owner), 1);
        assertEq(_ownerOf(id), owner);
    }

    function testBurn(uint256 id) public {
        address owner = _randomNonZeroAddress();

        _expectMintEvent(owner, id);
        token.mint(owner, id);

        vm.expectRevert(NotOwnerNorApproved.selector);
        token.burn(id);
        uint256 r = _random() % 3;
        if (r == 0) {
            _transferFrom(owner, owner, address(this), id);
            _expectBurnEvent(address(this), id);
            token.burn(id);
        }
        if (r == 1) {
            _setApprovalForAll(owner, address(this), true);
            _expectBurnEvent(owner, id);
            token.burn(id);
        }
        if (r == 2) {
            _approve(owner, address(this), id);
            _expectBurnEvent(owner, id);
            token.burn(id);
        }

        assertEq(token.balanceOf(owner), 0);

        vm.expectRevert(TokenDoesNotExist.selector);
        _ownerOf(id);
    }

    function testTransferFrom() public {
        address owner = _randomNonZeroAddress();
        token.mint(owner, 0);
        vm.prank(owner);
        token.transferFrom(owner, address(this), 0);
    }

    function testEverything(uint256) public {
        address[2] memory owners;
        uint256[][2] memory tokens;

        unchecked {
            (owners[0], owners[1]) = _owners();
            for (uint256 j; j != 2; ++j) {
                tokens[j] = new uint256[](_random() % 3);
            }

            for (uint256 j; j != 2; ++j) {
                for (uint256 i; i != tokens[j].length;) {
                    uint256 id = _random();

                    address owner;
                    try token.ownerOf(id) returns (address res) {
                        owner = res;
                    } catch {}

                    if (owner == address(0)) {
                        tokens[j][i++] = id;
                        _expectMintEvent(owners[j], id);
                        token.mint(owners[j], id);
                    }
                }
            }
            for (uint256 j; j != 2; ++j) {
                assertEq(token.balanceOf(owners[j]), tokens[j].length);
                for (uint256 i; i != tokens[j].length; ++i) {
                    _expectApprovalEvent(owners[j], address(this), tokens[j][i]);
                    _approve(owners[j], address(this), tokens[j][i]);
                }
            }
            for (uint256 j; j != 2; ++j) {
                for (uint256 i; i != tokens[j].length; ++i) {
                    assertEq(_getApproved(tokens[j][i]), address(this));
                    uint256 fromBalanceBefore = token.balanceOf(owners[j]);
                    uint256 toBalanceBefore = token.balanceOf(owners[j ^ 1]);
                    _expectTransferEvent(owners[j], owners[j ^ 1], tokens[j][i]);
                    _transferFrom(address(this), owners[j], owners[j ^ 1], tokens[j][i]);
                    assertEq(token.balanceOf(owners[j]), fromBalanceBefore - 1);
                    assertEq(token.balanceOf(owners[j ^ 1]), toBalanceBefore + 1);
                    assertEq(_getApproved(tokens[j][i]), address(0));
                }
            }
            for (uint256 j; j != 2; ++j) {
                for (uint256 i; i != tokens[j].length; ++i) {
                    assertEq(_ownerOf(tokens[j][i]), owners[j ^ 1]);
                }
            }
            if (_randomChance(2)) {
                for (uint256 j; j != 2; ++j) {
                    for (uint256 i; i != tokens[j].length; ++i) {
                        vm.expectRevert(NotOwnerNorApproved.selector);
                        _transferFrom(address(this), owners[j ^ 1], owners[j], tokens[j][i]);
                        _expectApprovalEvent(owners[j ^ 1], address(this), tokens[j][i]);
                        _approve(owners[j ^ 1], address(this), tokens[j][i]);
                        _expectTransferEvent(owners[j ^ 1], owners[j], tokens[j][i]);
                        _transferFrom(address(this), owners[j ^ 1], owners[j], tokens[j][i]);
                    }
                }
            } else {
                for (uint256 j; j != 2; ++j) {
                    vm.prank(owners[j ^ 1]);
                    _expectApprovalForAllEvent(owners[j ^ 1], address(this), true);
                    token.setApprovalForAll(address(this), true);
                    for (uint256 i; i != tokens[j].length; ++i) {
                        _expectTransferEvent(owners[j ^ 1], owners[j], tokens[j][i]);
                        _transferFrom(address(this), owners[j ^ 1], owners[j], tokens[j][i]);
                    }
                }
            }
            for (uint256 j; j != 2; ++j) {
                for (uint256 i; i != tokens[j].length; ++i) {
                    assertEq(_ownerOf(tokens[j][i]), owners[j]);
                }
            }
            for (uint256 j; j != 2; ++j) {
                for (uint256 i; i != tokens[j].length; ++i) {
                    address owner = token.ownerOf(tokens[j][i]);
                    vm.prank(owner);
                    token.burn(tokens[j][i]);
                }
            }
            for (uint256 j; j != 2; ++j) {
                assertEq(token.balanceOf(owners[j]), 0);
                for (uint256 i; i != tokens[j].length; ++i) {
                }
            }
        }
    }

    function testApprove(uint256 id) public {
        (address spender,) = _randomSigner();

        token.mint(address(this), id);

        _expectApprovalEvent(address(this), spender, id);
        _approve(address(this), spender, id);
        assertEq(_getApproved(id), spender);
    }

    function testApproveBurn(uint256 id) public {
        (address spender,) = _randomSigner();

        token.mint(address(this), id);

        _approve(address(this), spender, id);

        vm.prank(spender);
        token.burn(id);

        assertEq(token.balanceOf(address(this)), 0);

        assertEq(address(0), _getApproved(id));

        vm.expectRevert(TokenDoesNotExist.selector);
        _ownerOf(id);
    }

    function testApproveAll(uint256) public {
        (address operator,) = _randomSigner();
        bool approved = _randomChance(2);
        _expectApprovalForAllEvent(address(this), operator, approved);
        _setApprovalForAll(address(this), operator, approved);
        assertEq(token.isApprovedForAll(address(this), operator), approved);
    }

    function testTransferFromSingle(uint256 id) public {
        (address from, address to) = _owners();

        token.mint(from, id);

        if (_randomChance(2)) {
            uint256 r = _random() % 3;
            if (r == 0) {
                _approve(from, address(this), id);
                _expectTransferEvent(from, to, id);
                _transferFrom(address(this), from, to, id);
            }
            if (r == 1) {
                _setApprovalForAll(from, address(this), true);
                _expectTransferEvent(from, to, id);
                _transferFrom(address(this), from, to, id);
            }
            if (r == 2) {
                _expectTransferEvent(from, address(this), id);
                _transferFrom(from, from, address(this), id);
                _expectTransferEvent(address(this), to, id);
                _transferFrom(address(this), address(this), to, id);
            }
        } else {
            (address temp,) = _randomSigner();
            while (temp == from || temp == to) (temp,) = _randomSigner();
            
            _expectTransferEvent(from, temp, id);
            _transferFrom(from, from, temp, id);

            _expectTransferEvent(temp, to, id);
            _transferFrom(temp, temp, to, id);
        }

        assertEq(_getApproved(id), address(0));
        assertEq(_ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testTransferFromSelf(uint256 id) public {
        (address to,) = _randomSigner();

        token.mint(address(this), id);

        _transferFrom(address(this), address(this), to, id);

        assertEq(_getApproved(id), address(0));
        assertEq(_ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll(uint256 id) public {
        (address from, address to) = _owners();

        token.mint(from, id);

        _setApprovalForAll(from, address(this), true);

        _transferFrom(address(this), from, to, id);

        assertEq(_getApproved(id), address(0));
        assertEq(_ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA(uint256 id) public {
        (address from, address to) = _owners();

        token.mint(from, id);

        _setApprovalForAll(from, address(this), true);

        _safeTransferFrom(address(this), from, to, id);

        assertEq(_getApproved(id), address(0));
        assertEq(_ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient(uint256 id) public {
        (address from,) = _randomSigner();

        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, id);

        _setApprovalForAll(from, address(this), true);

        _safeTransferFrom(address(this), from, address(recipient), id);

        assertEq(_getApproved(id), address(0));
        assertEq(_ownerOf(id), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertEq(recipient.data(), "");
    }

    function testSafeTransferFromToERC721RecipientWithData(uint256 id, bytes memory data) public {
        (address from,) = _randomSigner();

        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, id);

        _setApprovalForAll(from, address(this), true);

        _safeTransferFrom(address(this), from, address(recipient), id, data);

        assertEq(recipient.data(), data);
        assertEq(recipient.id(), id);
        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);

        assertEq(_getApproved(id), address(0));
        assertEq(_ownerOf(id), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeMintToEOA(uint256 id) public {
        (address to,) = _randomSigner();

        token.safeMint(to, id);

        assertEq(_ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);
    }

    function testSafeMintToERC721Recipient(uint256 id) public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), id);

        assertEq(_ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertEq(to.data(), "");
    }

    function testSafeMintToERC721RecipientWithData(uint256 id, bytes memory data) public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), id, data);

        assertEq(_ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertEq(to.data(), data);
    }

    function testMintToZeroReverts(uint256 id) public {
        vm.expectRevert(TransferToZeroAddress.selector);
        token.mint(address(0), id);
    }

    function testDoubleMintReverts(uint256 id) public {
        (address to,) = _randomSigner();

        token.mint(to, id);
        vm.expectRevert(TokenAlreadyExists.selector);
        token.mint(to, id);
    }

    function testBurnNonExistentReverts(uint256 id) public {
        vm.expectRevert(TokenDoesNotExist.selector);
        token.burn(id);
    }

    function testDoubleBurnReverts(uint256 id) public {
        (address to,) = _randomSigner();

        token.mint(to, id);

        vm.prank(to);
        token.burn(id);

        vm.expectRevert(TokenDoesNotExist.selector);
        token.burn(id);
    }

    function testApproveNonExistentReverts(uint256 id, address to) public {
        vm.expectRevert(TokenDoesNotExist.selector);
        _approve(address(this), to, id);
    }

    function testApproveUnauthorizedReverts(uint256 id) public {
        (address owner, address to) = _owners();

        token.mint(owner, id);
        vm.expectRevert(NotOwnerNorApproved.selector);
        _approve(address(this), to, id);
    }

    function testTransferFromNotExistentReverts(address from, address to, uint256 id) public {
        vm.expectRevert(TokenDoesNotExist.selector);
        _transferFrom(address(this), from, to, id);
    }

    function testTransferFromWrongFromReverts(address to, uint256 id) public {
        (address owner, address from) = _owners();

        token.mint(owner, id);
        vm.expectRevert(TransferFromIncorrectOwner.selector);
        _transferFrom(address(this), from, to, id);
    }

    function testTransferFromToZeroReverts(uint256 id) public {
        token.mint(address(this), id);

        vm.expectRevert(TransferToZeroAddress.selector);
        _transferFrom(address(this), address(this), address(0), id);
    }

    function testTransferFromNotOwner(uint256 id) public {
        (address from, address to) = _owners();

        token.mint(from, id);

        vm.expectRevert(NotOwnerNorApproved.selector);
        _transferFrom(address(this), from, to, id);
    }

    function testSafeTransferFromToNonERC721RecipientReverts(uint256 id) public {
        token.mint(address(this), id);
        address to = address(new NonERC721Recipient());
        vm.expectRevert(TransferToNonERC721ReceiverImplementer.selector);
        _safeTransferFrom(address(this), address(this), address(to), id);
    }

    function testSafeTransferFromToNonERC721RecipientWithDataReverts(uint256 id, bytes memory data)
        public
    {
        token.mint(address(this), id);
        address to = address(new NonERC721Recipient());
        vm.expectRevert(TransferToNonERC721ReceiverImplementer.selector);
        _safeTransferFrom(address(this), address(this), to, id, data);
    }

    function testSafeTransferFromToRevertingERC721RecipientReverts(uint256 id) public {
        token.mint(address(this), id);
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        _safeTransferFrom(address(this), address(this), to, id);
    }

    function testSafeTransferFromToRevertingERC721RecipientWithDataReverts(
        uint256 id,
        bytes memory data
    ) public {
        token.mint(address(this), id);
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        _safeTransferFrom(address(this), address(this), to, id, data);
    }

    function testSafeTransferFromToERC721RecipientWithWrongReturnDataReverts(uint256 id) public {
        token.mint(address(this), id);
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(TransferToNonERC721ReceiverImplementer.selector);
        _safeTransferFrom(address(this), address(this), to, id);
    }

    function testSafeTransferFromToERC721RecipientWithWrongReturnDataWithDataReverts(
        uint256 id,
        bytes memory data
    ) public {
        token.mint(address(this), id);
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(TransferToNonERC721ReceiverImplementer.selector);
        _safeTransferFrom(address(this), address(this), to, id, data);
    }

    function testSafeMintToNonERC721RecipientReverts(uint256 id) public {
        address to = address(new NonERC721Recipient());
        vm.expectRevert(TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, id);
    }

    function testSafeMintToNonERC721RecipientWithDataReverts(uint256 id, bytes memory data)
        public
    {
        address to = address(new NonERC721Recipient());
        vm.expectRevert(TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, id, data);
    }

    function testSafeMintToRevertingERC721RecipientReverts(uint256 id) public {
        address to = address(new RevertingERC721Recipient());
        emit log_bytes(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        token.safeMint(to, id);
    }

    function testSafeMintToRevertingERC721RecipientWithDataReverts(uint256 id, bytes memory data)
        public
    {
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        token.safeMint(to, id, data);
    }

    function testSafeMintToERC721RecipientWithWrongReturnData(uint256 id) public {
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, id);
    }

    function testSafeMintToERC721RecipientWithWrongReturnDataWithData(uint256 id, bytes memory data)
        public
    {
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, id, data);
    }

    function testOwnerOfNonExistent(uint256 id) public {
        vm.expectRevert(TokenDoesNotExist.selector);
        _ownerOf(id);
    }
}