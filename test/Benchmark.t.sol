// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MockERC721Solady} from "./mock/MockERC721Solady.sol";
import {MockERC721Solmate} from "./mock/MockERC721Solmate.sol";
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

contract Benchmark is Test {
    MockERC721Solady public tokenSolady;
    MockERC721Solmate public tokenSolmate;
    MockERC721InlineAssembly public tokenInlineAssembly;

    ERC721Recipient public contractRecipient;

    function setUp() public {
        tokenInlineAssembly = new MockERC721InlineAssembly();
        tokenSolady = new MockERC721Solady();
        tokenSolmate = new MockERC721Solmate();

        contractRecipient = new ERC721Recipient();

        tokenInlineAssembly.mint(address(this), 10);
        tokenSolady.mint(address(this), 10);
        tokenSolmate.mint(address(this), 10);
    }

    function test_ownerOf_yul() public view {
        tokenInlineAssembly.ownerOf(10);
    }
    function test_ownerOf_solady() public view {
        tokenSolady.ownerOf(10);
    }
    function test_ownerOf_solmate() public view {
        tokenSolmate.ownerOf(10);
    }

    function test_balanceOf_yul() public view {
        tokenInlineAssembly.balanceOf(address(this));
    }

    function test_balanceOf_solady() public view {
        tokenSolady.balanceOf(address(this));
    }

    function test_balanceOf_solmate() public view {
        tokenSolmate.balanceOf(address(this));
    }

    function test_mint_yul() public {
        tokenInlineAssembly.mint(address(this), 5);
    }

    function test_mint_solady() public {
        tokenSolady.mint(address(this), 5);
    }

    function test_mint_solmate() public {
        tokenSolmate.mint(address(this), 5);
    }

    function test_safeMint_yul() public {
        tokenInlineAssembly.safeMint(address(contractRecipient), 5);
    }
    
    function test_safeMint_solady() public {
        tokenSolady.safeMint(address(contractRecipient), 5);
    }

    function test_safeMint_solmate() public {
        tokenSolmate.safeMint(address(contractRecipient), 5);
    }

    function test_burn_solady() public {
        tokenSolady.burn(10);
    }

    function test_burn_yul() public {
        tokenInlineAssembly.burn(10);
    }

    function test_burn_solmate() public {
        tokenSolmate.burn(10);
    }

    function test_transferFrom_yul() public {
        tokenInlineAssembly.transferFrom(address(this), address(0x789), 10);
    }

    function test_transferFrom_solady() public {
        tokenSolady.transferFrom(address(this), address(0x789), 10);
    }

    function test_transferFrom_solmate() public {
        tokenSolmate.transferFrom(address(this), address(0x789), 10);
    }

    function test_safeTransferFrom_yul() public {
        tokenInlineAssembly.safeTransferFrom(address(this), address(contractRecipient), 10);
    }
    
    function test_safeTransferFrom_solady() public {
        tokenSolady.safeTransferFrom(address(this), address(contractRecipient), 10);
    }
    
    function test_safeTransferFrom_solmate() public {
        tokenSolmate.safeTransferFrom(address(this), address(contractRecipient), 10);
    }

    function test_approve_yul() public {
        tokenInlineAssembly.approve(address(0x789), 10);
    }

    function test_approve_solady() public {
        tokenSolady.approve(address(0x789), 10);
    }

    function test_approve_solmate() public {
        tokenSolmate.approve(address(0x789), 10);
    }

    function test_setApprovalForAll_yul() public {
        tokenInlineAssembly.setApprovalForAll(address(0x789), true);
    }

    function test_setApprovalForAll_solady() public {
        tokenSolady.setApprovalForAll(address(0x789), true);
    }
    function test_setApprovalForAll_solmate() public {
        tokenSolmate.setApprovalForAll(address(0x789), true);
    }
}