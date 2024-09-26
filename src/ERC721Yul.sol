// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/*//////////////////////////////////////////////////////////////
BASE STORAGE SLOT: keccak256(abi.encode(uint256(keccak256("ERC721")) - 1)) & ~bytes32(uint256(0xff));
0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c600

STORAGE VARIABLE        OFFSET      SLOT
ownerOf                 0x00        0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c600
balanceOf               0x01        0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c601
getApproved             0x02        0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c602
isApprovedForAll        0x03        0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c603

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
            // Get owner stored at keccak256(concat(id, slot(ownerOf)))
            mstore(0x00, id)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c600)
            let owner := sload(keccak256(0x00, 0x40))

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
            owner := shr(96, shl(96, owner))
            // If owner == address(0), revert with error BalanceQueryForZeroAddress()
            if iszero(owner) {
                mstore(0x00, 0x8f4eb604)
                revert(0x1c, 0x04)
            }

            // Return balance stored at keccak256(concat(owner, slot(balanceOf)))
            mstore(0x00, owner)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c601)
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            return(0x00, 0x20)
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ERC721 APPROVAL
    //////////////////////////////////////////////////////////////*/

    function getApproved(uint256 id) public view virtual returns (address) {
        assembly {
            // Return approved operator stored at keccak256(concat(id, slot(getApproved)))
            mstore(0x00, id)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c602)
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            return(0x00, 0x20)
        }
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        assembly {
            owner := shr(96, shl(96, owner))
            operator := shr(96, shl(96, operator))

            // Hash owner with slot(isApprovedForAll)
            mstore(0x00, owner)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c603)
            // Hash operator with previous hash result.
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, operator)
            
            // Return approval stored at resultant slot
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            return(0x00, 0x20)
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public payable virtual {
        assembly {
            // Get owner stored at keccak256(concat(id, slot(ownerOf)))
            mstore(0x00, id)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c600)
            let owner := sload(keccak256(0x00, 0x40))

            // If owner == address(0), revert with error TokenDoesNotExist()
            if iszero(owner) {
                mstore(0x00, 0xceea21b6)
                revert(0x1c, 0x04)
            }

            // Check if operator is owner or approved party
            let operator := shr(96, shl(96, caller()))

            // Check: operator == owner
            let approval := eq(operator, owner)

            // Check: isApprovedForAll[owner][operator]
            mstore(0x00, owner)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c603)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, operator)
            
            approval := or(approval, sload(keccak256(0x00, 0x40)))

            // Check: getApproved[id]
            mstore(0x00, id)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c602)
            
            let getApprovedSlot := keccak256(0x00, 0x40)
            approval := or(approval, eq(operator, sload(getApprovedSlot)))

            // If not owner or approved, revert with error NotOwnerNorApproved()
            if iszero(approval) {
                mstore(0x00, 0x4b6e7f18)
                revert(0x1c, 0x04)
            }

            // Store first argument: spender as approved
            spender := shr(96, shl(96, spender))
            sstore(getApprovedSlot, spender)

            // emit Approval(owner, spender, id)
            log4(0, 0, 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, owner, spender, id)
        }
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        assembly {
            let owner := shr(96, shl(96, caller()))
            operator := shr(96, shl(96, operator))

            // Hash owner with slot(isApprovedForAll)
            mstore(0x00, owner)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c603)
            // Hash operator with previous hash result.
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, operator)
            
            // Store approval at slot
            sstore(keccak256(0x00, 0x40), approved)

            // emit ApprovalForAll(owner, operator, approval);
            mstore(0x00, approved)
            log3(0, 0x20, 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31, owner, operator)
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public payable virtual {
        assembly {
            from := shr(96, shl(96, from))
            to := shr(96, shl(96, to))

            // Get owner stored at keccak256(concat(id, slot(ownerOf)))
            mstore(0x00, id)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c600)
            let ownershipSlot := keccak256(0x00, 0x40)
            let owner := sload(ownershipSlot)

            // If owner == address(0), revert with error TokenDoesNotExist()
            if iszero(owner) {
                mstore(0x00, 0xceea21b6)
                revert(0x1c, 0x04)
            }

            // If from != owner, revert with error TransferFromIncorrectOwner()
            if iszero(eq(from, owner)) {
                mstore(0x00, 0xa1148100)
                revert(0x1c, 0x04)
            }

            // If to == address(0), revert with error TransferToZeroAddress()
            if iszero(to) {
                mstore(0x00, 0xea553b34)
                revert(0x1c, 0x04)
            }

            // Check if operator is owner or approved party
            let operator := shr(96, shl(96, caller()))

            // Check: operator == owner
            let approval := eq(operator, owner)

            // Check: isApprovedForAll[owner][operator]
            mstore(0x00, owner)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c603)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, operator)
            
            approval := or(approval, sload(keccak256(0x00, 0x40)))

            // Check: getApproved[id]
            mstore(0x00, id)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c602)
            let getApprovedSlot := keccak256(0x00, 0x40)
            approval := or(approval, eq(operator, sload(getApprovedSlot)))

            // If not owner or approved, revert with error NotOwnerNorApproved()
            if iszero(approval) {
                mstore(0x00, 0x4b6e7f18)
                revert(0x1c, 0x04)
            }

            // Update balances
            mstore(0x00, from)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c601)
            let balSlot := keccak256(0x00, 0x40)
            sstore(balSlot, sub(sload(balSlot), 1))

            mstore(0x00, to)
            balSlot := keccak256(0x00, 0x40)
            sstore(balSlot, add(sload(balSlot), 1))

            // Update ownership
            sstore(ownershipSlot, to)

            // Delete approval
            sstore(getApprovedSlot, 0x00)

            // emit Transfer(from, to, id)
            log4(0, 0, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, from, to, id)
        }
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
            to := shr(96, shl(96, to))

            // If minting to address(0), revert with error TransferToZeroAddress()
            if iszero(to) {
                mstore(0x00, 0xea553b34)
                revert(0x1c, 0x04)
            }

            // Get ownership slot keccak256(concat(id, slot(ownerOf))) and owner
            mstore(0x00, id)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c600)
            let ownerSlot := keccak256(0x00, 0x40)
            let owner := sload(ownerSlot)

            // If token has owner, revert with error TokenAlreadyExists()
            if owner {
                mstore(0x00, 0xc991cbb1)
                revert(0x1c, 0x04)
            }

            // Increment balance of `to` at slot keccak256(concat(to, slot(balanceOf)))
            mstore(0x00, to)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c601)
            let balSlot := keccak256(0x00, 0x40)
            sstore(balSlot, add(sload(balSlot), 1))

            // Store `to` as owner of token
            sstore(ownerSlot, to)

            // emit Transfer(address(0), to, id)
            log4(0, 0, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, 0x00, to, id)
        }
    }

    function _burn(uint256 id) internal virtual {
        assembly {
            // Get ownership slot keccak256(concat(id, slot(ownerOf))) and owner
            mstore(0x00, id)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c600)
            let ownerSlot := keccak256(0x00, 0x40)
            let owner := sload(ownerSlot)

            // If token has owner, revert with error TokenDoesNotExist()
            if iszero(owner) {
                mstore(0x00, 0xceea21b6)
                revert(0x1c, 0x04)
            }

            // Check if operator is owner or approved party
            let operator := shr(96, shl(96, caller()))

            // Check: operator == owner
            let approval := eq(operator, owner)

            // Check: isApprovedForAll[owner][operator]
            mstore(0x00, owner)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c603)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, operator)
            
            approval := or(approval, sload(keccak256(0x00, 0x40)))

            // Check: getApproved[id]
            mstore(0x00, id)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c602)
            
            let getApprovedSlot := keccak256(0x00, 0x40)
            approval := or(approval, eq(operator, sload(getApprovedSlot)))

            // If not owner or approved, revert with error NotOwnerNorApproved()
            if iszero(approval) {
                mstore(0x00, 0x4b6e7f18)
                revert(0x1c, 0x04)
            }

            // Decrement balance of owner at slot keccak256(concat(owner, slot(balanceOf)))
            mstore(0x00, owner)
            mstore(0x20, 0xf636dbdce80905a32bcc32ab76cebd6c5a0c63966fff1537b3bf6a12bc92c601)
            let balSlot := keccak256(0x00, 0x40)
            sstore(balSlot, sub(sload(balSlot), 1))

            // Delete ownership
            sstore(ownerSlot, 0x00)

            // Delete approval
            sstore(getApprovedSlot, 0x00)

            // emit Transfer(owner, address(0), id)
            log4(0, 0, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, owner, 0x00, id)
        }
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
        assembly {
            to := shr(96, shl(96, to))
            from := shr(96, shl(96, from))
            operator := shr(96, shl(96, operator))
            
            // If `to` is a contract:
            if extcodesize(to) {

                // Load and copy free memory pointer
                let ptr := mload(0x40)
                let ptrCopy := ptr

                // ABI encode call `onERC721Received.selector`
                mstore(ptr, 0x150b7a02)
                ptr := add(ptr, 0x20)

                mstore(ptr, operator)
                ptr := add(ptr, 0x20)

                mstore(ptr, from)
                ptr := add(ptr, 0x20)

                mstore(ptr, id)
                ptr := add(ptr, 0x20)

                mstore(ptr, 0x80)
                ptr := add(ptr, 0x20)

                let len := mload(data)
                data := add(data, 0x20)

                mstore(ptr, len)
                ptr := add(ptr, 0x20)

                for {} sgt(len, 0x00) { len := sub(len, 0x20)} {
                    mstore(ptr, mload(data))
                    data := add(data, 0x20)
                    ptr := add(ptr, 0x20)
                }

                // Call to.onERC721Received(...)
                let argStart := add(ptrCopy, 0x1c)
                let success := call(gas(), to, 0, argStart, sub(ptr, argStart), 0, 0)

                if success {
                    // Copy returned function sel
                    returndatacopy(0x1c, 0x00, returndatasize())

                    // If function sel != onERC721Received.selector, revert with error TransferToNonERC721ReceiverImplementer()
                    if iszero(eq(and(mload(0x00), 0xffffffff), 0x150b7a02)) {
                        mstore(0x00, 0xd1a57ed6)
                        revert(0x1c, 0x04)
                    }

                    stop()
                }

                // If call is unsuccessful but has return data, revert with that data.
                if returndatasize() {
                    returndatacopy(ptr, 0, returndatasize())
                    ptr := add(ptr, 0x20)

                    revert(sub(ptr, 0x20), returndatasize())
                }

                // If unsuccessful call, revert with error TransferToNonERC721ReceiverImplementer()
                mstore(0x00, 0xd1a57ed6)
                revert(0x1c, 0x04)
            }
        }
    }
}