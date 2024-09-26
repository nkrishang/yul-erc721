// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MockERC721Yul} from "./utils/MockERC721Yul.sol";
import {MockERC721Solady} from "./utils/MockERC721Solady.sol";
import {MockERC721 as MockERC721Solmate} from "./utils/MockERC721.sol";

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

contract Benchmark is Test {
    MockERC721Yul public tokenYul;
    MockERC721Solady public tokenSolady;
    MockERC721Solmate public tokenSolmate;

    ERC721Recipient public contractRecipient;

    function setUp() public {
        tokenYul = new MockERC721Yul();
        tokenSolady = new MockERC721Solady();
        tokenSolmate = new MockERC721Solmate();

        contractRecipient = new ERC721Recipient();
    }

    function test_ownerOf_yul() public {
        vm.pauseGasMetering();
        tokenYul.mint(address(0x123), 5);
        vm.resumeGasMetering();

        tokenYul.ownerOf(5);
    }
    function test_ownerOf_solady() public {
        vm.pauseGasMetering();
        tokenSolady.mint(address(0x123), 5);
        vm.resumeGasMetering();

        tokenSolady.ownerOf(5);
    }
    function test_ownerOf_solmate() public {
        vm.pauseGasMetering();
        tokenSolmate.mint(address(0x123), 5);
        vm.resumeGasMetering();

        tokenSolmate.ownerOf(5);
    }

    function test_balanceOf_yul() public {
        vm.pauseGasMetering();
        tokenYul.mint(address(0x123), 5);
        vm.resumeGasMetering();

        tokenYul.balanceOf(address(0x123));
    }

    function test_balanceOf_solady() public {
        vm.pauseGasMetering();
        tokenSolady.mint(address(0x123), 5);
        vm.resumeGasMetering();

        tokenSolady.balanceOf(address(0x123));
    }

    function test_balanceOf_solmate() public {
        vm.pauseGasMetering();
        tokenSolmate.mint(address(0x123), 5);
        vm.resumeGasMetering();

        tokenSolmate.balanceOf(address(0x123));
    }

    function test_mint_yul() public {
        tokenYul.mint(address(0x123), 5);
    }

    function test_mint_solady() public {
        tokenSolady.mint(address(0x123), 5);
    }

    function test_mint_solmate() public {
        tokenSolmate.mint(address(0x123), 5);
    }

    function test_safeMint_yul() public {
        tokenYul.safeMint(address(contractRecipient), 5);
    }
    
    function test_safeMint_solady() public {
        tokenSolady.safeMint(address(contractRecipient), 5);
    }

    function test_safeMint_solmate() public {
        tokenSolmate.safeMint(address(contractRecipient), 5);
    }

    function test_burn_yul() public {
        vm.pauseGasMetering();
        tokenYul.mint(address(0x123), 5);
        vm.prank(address(0x123));
        vm.resumeGasMetering();

        tokenYul.burn(5);
    }

    function test_burn_solady() public {
        vm.pauseGasMetering();
        tokenSolady.mint(address(0x123), 5);
        vm.prank(address(0x123));
        vm.resumeGasMetering();

        tokenSolady.burn(5);
    }

    function test_burn_solmate() public {
        vm.pauseGasMetering();
        tokenSolmate.mint(address(0x123), 5);
        vm.prank(address(0x123));
        vm.resumeGasMetering();

        tokenSolmate.burn(5);
    }

    function test_transferFrom_yul() public {
        vm.pauseGasMetering();
        tokenYul.mint(address(0x123), 5);
        vm.prank(address(0x123));
        vm.resumeGasMetering();

        tokenYul.transferFrom(address(0x123), address(0x789), 5);
    }

    function test_transferFrom_solady() public {
        vm.pauseGasMetering();
        tokenSolady.mint(address(0x123), 5);
        vm.prank(address(0x123));
        vm.resumeGasMetering();

        tokenSolady.transferFrom(address(0x123), address(0x789), 5);
    }

    function test_transferFrom_solmate() public {
        vm.pauseGasMetering();
        tokenSolmate.mint(address(0x123), 5);
        vm.prank(address(0x123));
        vm.resumeGasMetering();

        tokenSolmate.transferFrom(address(0x123), address(0x789), 5);
    }

    function test_safeTransferFrom_yul() public {
        vm.pauseGasMetering();
        tokenYul.mint(address(0x123), 5);
        vm.prank(address(0x123));
        vm.resumeGasMetering();

        tokenYul.transferFrom(address(0x123), address(contractRecipient), 5);
    }
    
    function test_safeTransferFrom_solady() public {
        vm.pauseGasMetering();
        tokenSolady.mint(address(0x123), 5);
        vm.prank(address(0x123));
        vm.resumeGasMetering();

        tokenSolady.transferFrom(address(0x123), address(contractRecipient), 5);
    }
    
    function test_safeTransferFrom_solmate() public {
        vm.pauseGasMetering();
        tokenSolmate.mint(address(0x123), 5);
        vm.prank(address(0x123));
        vm.resumeGasMetering();

        tokenSolmate.transferFrom(address(0x123), address(contractRecipient), 5);
    }

    function test_approve_yul() public {
        vm.pauseGasMetering();
        tokenYul.mint(address(0x123), 5);
        vm.prank(address(0x123));
        vm.resumeGasMetering();

        tokenYul.approve(address(0x789), 5);
    }

    function test_approve_solady() public {
        vm.pauseGasMetering();
        tokenSolady.mint(address(0x123), 5);
        vm.prank(address(0x123));
        vm.resumeGasMetering();

        tokenSolady.approve(address(0x789), 5);
    }

    function test_approve_solmate() public {
        vm.pauseGasMetering();
        tokenSolmate.mint(address(0x123), 5);
        vm.prank(address(0x123));
        vm.resumeGasMetering();

        tokenSolmate.approve(address(0x789), 5);
    }

    function test_setApprovalForAll_yul() public {
        tokenYul.setApprovalForAll(address(0x789), true);
    }

    function test_setApprovalForAll_solady() public {
        tokenSolady.setApprovalForAll(address(0x789), true);
    }
    function test_setApprovalForAll_solmate() public {
        tokenSolmate.setApprovalForAll(address(0x789), true);
    }
}