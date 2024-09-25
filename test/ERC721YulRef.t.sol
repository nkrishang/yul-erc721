// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;


// import {Test, console} from "forge-std/Test.sol";
// import {ERC721Yul} from "../src/ERC721Yul.sol";
// // import {ERC721Solady} from "../src/ERC721Solady.sol";
// import "./utils/SoladyTest.sol";

// abstract contract ERC721TokenReceiver {
//     function onERC721Received(address, address, uint256, bytes calldata)
//         external
//         virtual
//         returns (bytes4)
//     {
//         return ERC721TokenReceiver.onERC721Received.selector;
//     }
// }

// contract ERC721Recipient is ERC721TokenReceiver {
//     address public operator;
//     address public from;
//     uint256 public id;
//     bytes public data;

//     function onERC721Received(address _operator, address _from, uint256 _id, bytes calldata _data)
//         public
//         virtual
//         override
//         returns (bytes4)
//     {
//         operator = _operator;
//         from = _from;
//         id = _id;
//         data = _data;

//         return ERC721TokenReceiver.onERC721Received.selector;
//     }
// }

// contract RevertingERC721Recipient is ERC721TokenReceiver {
//     function onERC721Received(address, address, uint256, bytes calldata)
//         public
//         virtual
//         override
//         returns (bytes4)
//     {
//         revert(string(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector)));
//     }
// }

// contract WrongReturnDataERC721Recipient is ERC721TokenReceiver {
//     function onERC721Received(address, address, uint256, bytes calldata)
//         public
//         virtual
//         override
//         returns (bytes4)
//     {
//         return 0xCAFEBEEF;
//     }
// }

// contract NonERC721Recipient {}

// contract ERC721YulTest is SoladyTest {
//     ERC721Yul public token;
//     // ERC721Solady public solady;

//     function setUp() public {
//         token = new ERC721Yul();
//         // solady = new ERC721Solady();
//     }
    
//     event Approval(address indexed owner, address indexed approved, uint256 indexed id);
//     function _expectApprovalEvent(address owner, address approved, uint256 id) internal {
//         vm.expectEmit(true, true, true, true);
//         emit Approval(_cleaned(owner), _cleaned(approved), id);
//     }

//     function _ownerOf(uint256 id) internal view returns (address) {
//         return token.ownerOf(id);
//     }

//     function _approve(address caller, address spender, uint256 id) internal {
//         if (_randomChance(2)) {
//             vm.prank(caller);
//             token.approve(spender, id);
//         } else {
//             vm.prank(_brutalized(caller));
//             token.approve(spender, id);
//         }
//     }

//     function _getApproved(uint256 id) internal view returns (address) {
//         return token.getApproved(id);
//     }

//     // function testApproveYul(uint256 id) public {
//     //     (address spender,) = _randomSigner();

//     //     token.mint(address(this), id);

//     //     _expectApprovalEvent(address(this), spender, id);
//     //     _approve(address(this), spender, id);
//     //     assertEq(_getApproved(id), spender);
//     // }

//     function test_name() public {
//         string memory name = token.name();
//         assertEq(name, "TEST NFT");
//     }

//     function test_slot() public {
//         bytes32 slot = keccak256(abi.encode(uint256(keccak256("ERC721")) - 1)) & ~bytes32(uint256(0xff));
//         emit log_bytes32(slot);

//         bytes32 slot1;
//         assembly {
//             slot1 := add(slot, 1)
//         }
//         emit log_bytes32(slot1);
//     }

//     function test_event() public {
//         bytes32 sig = keccak256("ApprovalForAll(address,address,bool)");
//         emit log_bytes32(sig);
//     }

//     // function test_benchmark_mintYul() public {
//     //     token.mint(address(this), 5);
//     // }
//     // function test_benchmark_mintSolady() public {
//     //     solady.mint(address(this), 5);
//     // }

//     error TransferToZeroAddress();
//     function test_error() public {
//         emit log_bytes32(TransferToZeroAddress.selector);
//     }

//     // 0x150b7a02 | argStart | 220-224
//     // 0000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e1496 | 224 - 256 | operator
//     // 0000000000000000000000000000000000000000000000000000000000000000 | 256 - 288 | from
//     // 0000000000000000000000002e234dae75c793f67a35089c9d99245e1c58470b | 288 - 320 | to
//     // 0000000000000000000000000000000000000000000000000000000000000000 | 320 - 352 | id
//     // 0000000000000000000000000000000000000000000000000000000000000084 | 352 - 384 | data offset
//     // 0000000000000000000000000000000000000000000000000000000000000005 | 384 - 416 | length
//     // 68656c6c6f000000000000000000000000000000000000000000000000000000 | 416 - 448 | data

//     // 0x00000000000000000000000000000000000000000000000000000000000001c0 - 448
//     // 0x00000000000000000000000000000000000000000000000000000000000000dc - 220

//     // function testSafeMintToEOA(uint256 id) public {
//     //     (address to,) = _randomSigner();

//     //     token.safeMint(to, id);

//     //     assertEq(_ownerOf(id), address(to));
//     //     assertEq(token.balanceOf(address(to)), 1);
//     // }

//     // function testSafeMintToERC721RecipientSingleSolady() public {
//     //     ERC721Recipient to = new ERC721Recipient();
//     //     uint256 id = 10;

//     //     solady.safeMint(address(to), id);

//     //     assertEq(solady.ownerOf(id), address(to));
//     //     assertEq(solady.balanceOf(address(to)), 1);

//     //     assertEq(to.operator(), address(this));
//     //     assertEq(to.from(), address(0));
//     //     assertEq(to.id(), id);
//     //     assertEq(to.data(), "");
//     // }

//     // function testSafeMintToERC721RecipientSingle() public {
//     //     ERC721Recipient to = new ERC721Recipient();
//     //     uint256 id = 10;

//     //     token.safeMint(address(to), id);

//     //     assertEq(_ownerOf(id), address(to));
//     //     assertEq(token.balanceOf(address(to)), 1);

//     //     assertEq(to.operator(), address(this));
//     //     assertEq(to.from(), address(0));
//     //     assertEq(to.id(), id);
//     //     assertEq(to.data(), "");
//     // }

//     // function testSafeMintToERC721RecipientWithData(uint256 id, bytes memory data) public {
//     //     ERC721Recipient to = new ERC721Recipient();

//     //     token.safeMint(address(to), id, data);

//     //     assertEq(_ownerOf(id), address(to));
//     //     assertEq(token.balanceOf(address(to)), 1);

//     //     assertEq(to.operator(), address(this));
//     //     assertEq(to.from(), address(0));
//     //     assertEq(to.id(), id);
//     //     assertEq(to.data(), data);
//     // }

//     // function testSafeMintToNonERC721RecipientWithDataReverts(uint256 id, bytes memory data)
//     //     public
//     // {
//     //     address to = address(new NonERC721Recipient());
//     //     vm.expectRevert(TransferToNonERC721ReceiverImplementer.selector);
//     //     token.safeMint(to, id, data);
//     // }

//     // function testSafeMintToRevertingERC721RecipientReverts(uint256 id) public {
//     //     address to = address(new RevertingERC721Recipient());
//     //     emit log_bytes(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
//     //     vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
//     //     token.safeMint(to, id);
//     // }

//     // function testSafeMintToRevertingERC721RecipientWithDataReverts(uint256 id, bytes memory data)
//     //     public
//     // {
//     //     address to = address(new RevertingERC721Recipient());
//     //     vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
//     //     token.safeMint(to, id, data);
//     // }

//     // function testSafeMintToERC721RecipientWithWrongReturnData(uint256 id) public {
//     //     address to = address(new WrongReturnDataERC721Recipient());
//     //     vm.expectRevert(TransferToNonERC721ReceiverImplementer.selector);
//     //     token.safeMint(to, id);
//     // }

//     // function testSafeMintToERC721RecipientWithWrongReturnDataWithData(uint256 id, bytes memory data)
//     //     public
//     // {
//     //     address to = address(new WrongReturnDataERC721Recipient());
//     //     vm.expectRevert(TransferToNonERC721ReceiverImplementer.selector);
//     //     token.safeMint(to, id, data);
//     // }
// }
