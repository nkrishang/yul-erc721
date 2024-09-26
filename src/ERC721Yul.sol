// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*//////////////////////////////////////////////////////////////

    @dev STORAGE LAYOUT

    The ownerOf(id) slot is given by:
    ```
    mstore(0x00, id)
    ownershipSlot := keccack256(0x00, 0x20)
    ```

    The approved(id) slot is given by:
    ```
    approveSlot := add(ownershipSlot, 1)
    ```

    The balanceOf(owner) slot is given by:
    ```
    mstore(0x00, owner)
    balanceSlot := keccak256(0x00, 0x20)
    ```

    The isApprovedForAll[owner][operator] slot is given by:
    ```
    mstore(0x14, operator)
    mstore(0x00, owner)
    operatorApprovalSlot := keccack256(0x0c, 0x28)
    ```
//////////////////////////////////////////////////////////////*/

abstract contract ERC721Yul {

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    function name() external pure returns (string memory) {
        assembly {
            // Store offset at 1st word at 0x00
            mstore(0x00, 0x20)

            // Here, len=0x08 and str=0x54455354204e4654 ("TEST NFT")
            // Store pack(len + string data) starting at 0x20 + len
            // This ensures len is the rightmost bits of the 2nd word
            // and the string data is stored in the 3rd word
            //
            // See https://docs.huff.sh/tutorial/hello-world/#advanced-topic-the-seaport-method-of-returning-strings
            mstore(0x28, 0x854455354204e4654)
            return(0x00, 0x60)
        }
    }

    function symbol() external pure returns (string memory) {
        assembly {
            // len=0x04 and str=0x54455354 ("TEST")
            // See `name` for assembly explanation
            mstore(0x00, 0x20)
            mstore(0x24, 0x454455354)
            return(0x00, 0x60)
        }
    }

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                        ERC721 BALANCE/OWNER
    //////////////////////////////////////////////////////////////*/

    function ownerOf(uint256 id) public view virtual returns (address) {
        assembly {
            // Get owner
            mstore(0x00, id)
            let owner := sload(keccak256(0x00, 0x20))

            // If owner == address(0), revert with error TokenDoesNotExist()
            if iszero(owner) {
                mstore(0x00, 0xceea21b6)
                revert(0x1c, 0x04)
            }
            
            mstore(0x00, owner)
            return(0x00, 0x20)
        }
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        assembly {
            // Clear upper 96 bits
            owner := shr(96, shl(96, owner))
            
            // If owner == address(0), revert with error BalanceQueryForZeroAddress()
            if iszero(owner) {
                mstore(0x00, 0x8f4eb604)
                revert(0x1c, 0x04)
            }

            // Return balance
            mstore(0x00, owner)
            mstore(0x00, sload(keccak256(0x00, 0x20)))
            return(0x00, 0x20)
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ERC721 APPROVAL
    //////////////////////////////////////////////////////////////*/

    function getApproved(uint256 id) public view virtual returns (address) {
        assembly {
            // Return approved operator
            mstore(0x00, id)
            mstore(0x00, sload(add(keccak256(0x00, 0x20), 1)))
            return(0x00, 0x20)
        }
    }

    function isApprovedForAll(address owner, address operator) public virtual returns (bool) {
        assembly {
            // Get and return approval
            mstore(0x14, shr(96, shl(96, operator)))
            mstore(0x00, shr(96, shl(96, owner)))
            mstore(0x00, sload(keccak256(0x0c, 0x28)))
            return(0x00, 0x20)
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public payable virtual {
        assembly {
            // Get owner
            mstore(0x00, id)
            let ownershipSlot := keccak256(0x00, 0x20)
            let owner := sload(ownershipSlot)

            // If owner == address(0), revert with error TokenDoesNotExist()
            if iszero(owner) {
                mstore(0x00, 0xceea21b6)
                revert(0x1c, 0x04)
            }

            // If not owner or approved, revert with error NotOwnerNorApproved()
            if iszero(eq(caller(), owner)) {
                
                mstore(0x14, caller())
                mstore(0x00, owner)

                if iszero(sload(keccak256(0x0c, 0x28))) {

                    if iszero(sload(add(ownershipSlot, 1))) {
                        mstore(0x00, 0x4b6e7f18)
                        revert(0x1c, 0x04)
                    }
                }
            }

            // Approve spender for token
            spender := shr(96, shl(96, spender))
            sstore(add(ownershipSlot, 1), spender)

            // emit Approval(owner, spender, id)
            log4(0, 0, 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, owner, spender, id)
        }
    }

    function setApprovalForAll(address operator, bool approved) public payable virtual {
        assembly {
            let op := shr(96, shl(96, operator))
            
            // Store approval
            mstore(0x14, op)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x28), approved)

            // emit ApprovalForAll(owner, operator, approval);
            mstore(0x00, approved)
            log3(0, 0x20, 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31, caller(), op)
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public payable virtual {
        assembly {
            let recipient := shr(96, shl(96, to))
            let sender := shr(96, shl(96, from))

            // Get owner
            mstore(0x00, id)
            let ownershipSlot := keccak256(0x00, 0x20)
            let owner := sload(ownershipSlot)

            if iszero(owner) {
                // If owner == address(0), revert with error TokenDoesNotExist()
                mstore(0x00, 0xceea21b6)
                revert(0x1c, 0x04)
            }

            if iszero(eq(sender, owner)) {
                // If from != owner, revert with error TransferFromIncorrectOwner()
                mstore(0x00, 0xa1148100)
                revert(0x1c, 0x04)
            }

            if iszero(recipient) {
                // If to == address(0), revert with error TransferToZeroAddress()
                mstore(0x00, 0xea553b34)
                revert(0x1c, 0x04)
            }

            // Update balances
            mstore(0x00, recipient)
            let recipientBal := keccak256(0x00, 0x20)
            sstore(recipientBal, add(sload(recipientBal), 1))
            
                              
            mstore(0x00, owner)
            let ownerBal := keccak256(0x00, 0x20)
            sstore(ownerBal, sub(sload(ownerBal), 1))

            {
                // If not owner or approved, revert with error NotOwnerNorApproved()
                let approveAddress := sload(add(ownershipSlot, 1))
                if iszero(eq(caller(), owner)) {

                    if iszero(approveAddress) {
                        mstore(0x14, caller())
                        mstore(0x00, owner)

                        if iszero(sload(keccak256(0x0c, 0x28))) {
                            mstore(0x00, 0x4b6e7f18)
                            revert(0x1c, 0x04)
                        }   
                    }
                }
                // Delete approval
                if approveAddress { sstore(add(ownershipSlot, 1), 0x00) }                    
            }

            // Update ownership
            sstore(ownershipSlot, recipient)

            // emit Transfer(from, to, id)
            log4(0, 0, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, sender, recipient, id)
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public payable virtual {
        transferFrom(from, to, id);
        _safeTransferCheck(from, to, id, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public payable virtual {
        transferFrom(from, to, id);
        _safeTransferCheck(from, to, id, data);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        assembly {
            // ERC165 Interface ID for ERC165 0x01ffc9a7
            // ERC165 Interface ID for ERC721 0x80ac58cd
            // ERC165 Interface ID for ERC721Metadata 0x5b5e139f
            let b := or(or(eq(interfaceId, 0x01ffc9a7), eq(interfaceId, 0x80ac58cd)), eq(interfaceId, 0x5b5e139f))
            mstore(0x00, b)
            return(0x00, 0x20)
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        assembly {
            let recipient := shr(96, shl(96, to))

            // If minting to address(0), revert with error TransferToZeroAddress()
            if iszero(recipient) {
                mstore(0x00, 0xea553b34)
                revert(0x1c, 0x04)
            }

            // Get owner
            mstore(0x00, id)
            let ownershipSlot := keccak256(0x00, 0x20)
            let owner := sload(ownershipSlot)

            // If token has owner, revert with error TokenAlreadyExists()
            if owner {
                mstore(0x00, 0xc991cbb1)
                revert(0x1c, 0x04)
            }

            // Increment balance of `to` at slot keccak256(concat(to, slot(balanceOf)))
            mstore(0x00, recipient)
            let balSlot := keccak256(0x00, 0x20)
            sstore(balSlot, add(sload(balSlot), 1))

            // Store `to` as owner of token
            sstore(ownershipSlot, recipient)

            // emit Transfer(address(0), to, id)
            log4(0, 0, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, 0x00, recipient, id)
        }
    }

    function _burn(uint256 id) internal virtual {
        assembly {
            // Get owner
            mstore(0x00, id)
            let ownershipSlot := keccak256(0x00, 0x20)
            let owner := sload(ownershipSlot)

            // If token has owner, revert with error TokenDoesNotExist()
            if iszero(owner) {
                mstore(0x00, 0xceea21b6)
                revert(0x1c, 0x04)
            }

            // If not owner or approved, revert with error NotOwnerNorApproved()
            let approvedAddress := sload(add(ownershipSlot, 1))

            if iszero(eq(caller(), owner)) {
                
                mstore(0x14, caller())
                mstore(0x00, owner)

                if iszero(sload(keccak256(0x0c, 0x28))) {

                    if iszero(approvedAddress) {
                        mstore(0x00, 0x4b6e7f18)
                        revert(0x1c, 0x04)
                    }
                }
            }

            // Decrement balance of owner at slot keccak256(concat(owner, slot(balanceOf)))
            mstore(0x00, owner)
            let balSlot := keccak256(0x00, 0x20)
            sstore(balSlot, sub(sload(balSlot), 1))

            // Delete ownership
            sstore(ownershipSlot, 0x00)

            // Delete approval
            if approvedAddress { sstore(add(ownershipSlot, 1), 0x00) }

            // emit Transfer(owner, address(0), id)
            log4(0, 0, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, owner, 0x00, id)
        }
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes calldata data
    ) internal virtual {
        _mint(to, id);
        _safeTransferCheck(address(0), to, id, data);
    }

    function _safeTransferCheck(address from, address to, uint256 id, bytes memory data) internal {
        assembly {
            let bitmaskAddress := shr(96, not(0))

            let ptr := mload(0x40) 
            // If `to` is a contract:
            if extcodesize(and(to, bitmaskAddress)) {
                // ABI encode call `onERC721Received.selector`
                mstore(ptr, 0x150b7a02)
                mstore(add(ptr, 0x20), caller())
                mstore(add(ptr, 0x40), and(from, bitmaskAddress))
                mstore(add(ptr, 0x60), id)
                mstore(add(ptr, 0x80), 0x80)

                let len := mload(data)
                mstore(add(ptr, 0xa0), len)
                
                // Call datacopy precompile 0x04 to copy `bytes memory data` into memory
                if len { pop(staticcall(gas(), 0x04, add(data, 0x20), len, add(ptr, 0xc0), len)) }
                
                // Call to.onERC721Received(...)
                if iszero(call(gas(), and(to, bitmaskAddress), 0, add(ptr, 0x1c), add(len, 0xa4), ptr, 0x20)) {
                    if returndatasize() {
                        returndatacopy(ptr, 0, returndatasize())
                        revert(ptr, returndatasize())
                    }
                }

                // If unsuccessful call, revert with error TransferToNonERC721ReceiverImplementer()
                if iszero(eq(0x150b7a02, shr(224, mload(ptr)))) {
                    mstore(0x00, 0xd1a57ed6)
                    revert(0x1c, 0x04)    
                }
            }
        }
    }
}