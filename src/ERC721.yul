// SPDX-License-Identifier: MIT

object "ERC721" {
    code {
        // Deploy contract and return bytecode
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {
        code {
            // Dispatch
            switch selector()

        /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE/LOGIC
        //////////////////////////////////////////////////////////////*/
            
            // `name()`
            case 0x06fdde03 {
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

            // `symbol()`
            case 0x95d89b41 {
                // len=0x04 and str=0x54455354 ("TEST")
                // See `name` for assembly explanation
                mstore(0x00, 0x20)
                mstore(0x24, 0x454455354)
                return(0x00, 0x60)
            }

            // TODO: tokenURI

        /*//////////////////////////////////////////////////////////////
                            ERC721 BALANCE/OWNER
        //////////////////////////////////////////////////////////////*/

            // `ownerOf(uint256 id)
            case 0x6352211e {
                let owner := sload(_ownerOfSlot(calldataload(0x04)))
                assertOwnerNotAddressZero(owner)
                returnValue(owner)
            }

            // `balanceOf(address owner)`
            case 0x70a08231 {
                let owner := cleanAddress(calldataload(0x04))
                assertOwnerNotAddressZero(owner)
                returnValue(sload(_balanceOfSlot(owner)))
            }
        
        /*//////////////////////////////////////////////////////////////
                                ERC721 APPROVAL
        //////////////////////////////////////////////////////////////*/

            // `getApproved(uint256 id)`
            case 0x081812fc {
                returnValue(sload(_getApprovedSlot(calldataload(0x04))))
            }

            // `isApprovedForAll(address owner, address operator)`
            case 0xe985e9c5 {
                returnValue(sload(_isApprovedForAllSlot(cleanAddress(calldataload(0x04)), cleanAddress(calldataload(0x24)))))
            }
        
        /*//////////////////////////////////////////////////////////////
                                ERC721 LOGIC
        //////////////////////////////////////////////////////////////*/

            // `approve(address spender, uint256 id)`
            case 0x095ea7b3 {
                // Get owner
                let id := calldataload(0x24)
                let ownershipSlot := _ownerOfSlot(id)
                let owner := sload(ownershipSlot)

                assertOwnerNotAddressZero(owner)
                assertOperatorIsOwnerOrApproved(caller(), owner, ownershipSlot)

                // Approve spender for token
                let spender := cleanAddress(calldataload(0x04))
                sstore(add(ownershipSlot, 1), spender)

                // emit Approval(owner, spender, id)
                log4(0, 0, 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, owner, spender, id)
            }

            // `setApprovalForAll(address operator, bool approval)`
            case 0xa22cb465 {
                let operator := cleanAddress(calldataload(0x04))
                let approval := calldataload(0x24)
                
                // Store approval
                sstore(_isApprovedForAllSlot(caller(), operator), approval)

                // emit ApprovalForAll(owner, operator, approval);
                mstore(0x00, approval)
                log3(0, 0x20, 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31, caller(), operator)
            }

            // `transferFrom(address from, address to, uint256 id)`
            case 0x23b872dd {
                _transferFrom(cleanAddress(calldataload(0x04)), cleanAddress(calldataload(0x24)), calldataload(0x44))
            }

            // `safeTransferFrom(address from, address to, uint256 id)`
            case 0x42842e0e {
                let from := cleanAddress(calldataload(0x04))
                let to := cleanAddress(calldataload(0x24))
                let id := calldataload(0x44)
                
                _transferFrom(from, to, id)

                // If `to` is a contract:
                if extcodesize(to) {
                    // ABI encode call `onERC721Received.selector`
                    mstore(0x00, 0x150b7a02)
                    mstore(0x20, caller())
                    mstore(0x40, from)
                    mstore(0x60, id)
                    mstore(0x80, 0x80)
                    mstore(0xa0, 0x00)
                    
                    // Call to.onERC721Received(...)
                    if iszero(call(gas(), to, 0, 0x1c, 0xa4, 0x00, 0x20)) {
                        if returndatasize() {
                            returndatacopy(0, 0, returndatasize())
                            revert(0, returndatasize())
                        }
                    }

                    // If call returns with unexpected data, revert with error TransferToNonERC721ReceiverImplementer()
                    if iszero(eq(0x150b7a02, shr(224, mload(0x00)))) {
                        mstore(0x00, 0xd1a57ed6)
                        revert(0x1c, 0x04)    
                    }
                }
            }

            // `safeTransferFrom(address from, address to, uint256 id, bytes calldata data)`
            case 0xb88d4fde {
                let from := cleanAddress(calldataload(0x04))
                let to := cleanAddress(calldataload(0x24))
                let id := calldataload(0x44)
                
                _transferFrom(from, to, id)

                // If `to` is a contract:
                if extcodesize(to) {
                    // ABI encode call `onERC721Received.selector`
                    mstore(0x00, 0x150b7a02)
                    mstore(0x20, caller())
                    mstore(0x40, from)
                    mstore(0x60, id)
                    mstore(0x80, 0x80)
                    
                    // Store bytes data len
                    let len := calldataload(0x84)
                    mstore(0xa0, len)
                    
                    // Copy bytes data into memory
                    if len { calldatacopy(0xc0, 0xa4, len) }
                    
                    // Call to.onERC721Received(...)
                    if iszero(call(gas(), to, 0, 0x1c, add(len, 0xa4), 0x00, 0x20)) {
                        if returndatasize() {
                            returndatacopy(0, 0, returndatasize())
                            revert(0, returndatasize())
                        }
                    }

                    // If call returns with unexpected data, revert with error TransferToNonERC721ReceiverImplementer()
                    if iszero(eq(0x150b7a02, shr(224, mload(0x00)))) {
                        mstore(0x00, 0xd1a57ed6)
                        revert(0x1c, 0x04)    
                    }
                }
            }

        /*//////////////////////////////////////////////////////////////
                                ERC165 LOGIC
        //////////////////////////////////////////////////////////////*/
        
        // `supportsInterface(bytes4 interfaceId)` 
        case 0x01ffc9a7 {
            let interfaceId := calldataload(0x04)
            // ERC165 Interface ID for ERC165 0x01ffc9a7
            // ERC165 Interface ID for ERC721 0x80ac58cd
            // ERC165 Interface ID for ERC721Metadata 0x5b5e139f
            let b := or(or(eq(interfaceId, 0x01ffc9a7), eq(interfaceId, 0x80ac58cd)), eq(interfaceId, 0x5b5e139f))
            returnValue(b)
        }

        /*//////////////////////////////////////////////////////////////
                                MINT/BURN LOGIC
        //////////////////////////////////////////////////////////////*/
        
        // `mint(address to, uint256 id)`
        case 0x40c10f19 {
            _mint(cleanAddress(calldataload(0x04)), calldataload(0x24))
        }

        // `safeMint(address to, uint256 id)`
        case 0xa1448194 {
            let to := cleanAddress(calldataload(0x04))
            let id := calldataload(0x24)
                
            _mint(to, id)

            // If `to` is a contract:
            if extcodesize(to) {
                // ABI encode call `onERC721Received.selector`
                mstore(0x00, 0x150b7a02)
                mstore(0x20, caller())
                mstore(0x40, 0x00)
                mstore(0x60, id)
                mstore(0x80, 0x80)
                mstore(0xa0, 0x00)
                
                // Call to.onERC721Received(...)
                if iszero(call(gas(), to, 0, 0x1c, 0xa4, 0x00, 0x20)) {
                    if returndatasize() {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }

                // If call returns with unexpected data, revert with error TransferToNonERC721ReceiverImplementer()
                if iszero(eq(0x150b7a02, shr(224, mload(0x00)))) {
                    mstore(0x00, 0xd1a57ed6)
                    revert(0x1c, 0x04)    
                }
            }
        }

        // `safeMint(address to, uint256 id, bytes calldata data)`
        case 0x8832e6e3 {
            let to := cleanAddress(calldataload(0x04))
            let id := calldataload(0x24)
            
            _mint(to, id)

            // If `to` is a contract:
            if extcodesize(to) {
                // ABI encode call `onERC721Received.selector`
                mstore(0x00, 0x150b7a02)
                mstore(0x20, caller())
                mstore(0x40, 0x00)
                mstore(0x60, id)
                mstore(0x80, 0x80)
                
                // Store bytes data len
                let len := calldataload(0x64)
                mstore(0xa0, len)
                
                // Copy bytes data into memory
                if len { calldatacopy(0xc0, 0x84, len) }
                
                // Call to.onERC721Received(...)
                if iszero(call(gas(), to, 0, 0x1c, add(len, 0xa4), 0x00, 0x20)) {
                    if returndatasize() {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }

                // If call returns with unexpected data, revert with error TransferToNonERC721ReceiverImplementer()
                if iszero(eq(0x150b7a02, shr(224, mload(0x00)))) {
                    mstore(0x00, 0xd1a57ed6)
                    revert(0x1c, 0x04)    
                }
            }
        }

        // `burn(uint256 id)
        case 0x42966c68 {

            let id := calldataload(0x04)

            // Get owner
            let ownershipSlot := _ownerOfSlot(id)
            let owner := sload(ownershipSlot)
            
            assertOwnerNotAddressZero(owner)

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

            // Decrement balance of owner at slot keccak256(concat(owner, slot(balanceOf)))
            let balSlot := _balanceOfSlot(owner)
            sstore(balSlot, sub(sload(balSlot), 1))

            // Delete ownership
            sstore(ownershipSlot, 0x00)

            // emit Transfer(owner, address(0), id)
            log4(0, 0, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, owner, 0x00, id)
        }
        
        /*//////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
        //////////////////////////////////////////////////////////////*/

            function _transferFrom(from, to, id) {
                // Get owner
                let ownershipSlot := _ownerOfSlot(id)
                let owner := sload(ownershipSlot)

                assertOwnerNotAddressZero(owner)
                assertTransferFromCorrectOwner(from, owner)
                assertRecipientNotAddressZero(to)

                // Update balances
                let recipientBalSlot := _balanceOfSlot(to)
                sstore(recipientBalSlot, add(sload(recipientBalSlot), 1))
                
                let ownerBalSlot := _balanceOfSlot(owner)
                sstore(ownerBalSlot, sub(sload(ownerBalSlot), 1))

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
                sstore(ownershipSlot, to)

                // emit Transfer(from, to, id)
                log4(0, 0, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, from, to, id)
            }
            
            function _mint(to, id) {
                assertRecipientNotAddressZero(to)
    
                // Get owner
                let ownershipSlot := _ownerOfSlot(id)
                assertOwnerDoesNotExist(sload(ownershipSlot))
    
                // Increment balance of `to` at slot keccak256(concat(to, slot(balanceOf)))
                let balSlot := _balanceOfSlot(to)
                sstore(balSlot, add(sload(balSlot), 1))
    
                // Store `to` as owner of token
                sstore(ownershipSlot, to)
    
                // emit Transfer(address(0), to, id)
                log4(0, 0, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, 0x00, to, id)
            }

        /*//////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
        //////////////////////////////////////////////////////////////*/

            function selector() -> v {
                v := shr(224, calldataload(0x00))
            }

            function cleanAddress(addr) -> cleaned {
                cleaned := shr(96, shl(96, addr))
            }

            function _ownerOfSlot(id) -> slot {
                mstore(0x00, id)
                slot := keccak256(0x00, 0x20)
            }

            function _balanceOfSlot(owner) -> slot {
                mstore(0x00, owner)
                slot := keccak256(0x00, 0x20)
            }

            function _getApprovedSlot(id) -> slot {
                mstore(0x00, id)
                slot := add(keccak256(0x00, 0x20), 1)
            }

            function _isApprovedForAllSlot(owner, operator) -> slot {
                mstore(0x14, operator)
                mstore(0x00, owner)
                slot := keccak256(0x0c, 0x28)
            }

            function assertOwnerNotAddressZero(owner) {
                // If owner == address(0), revert with error TokenDoesNotExist()
                if iszero(owner) {
                    mstore(0x00, 0xceea21b6)
                    revert(0x1c, 0x04)
                }
            }

            function assertOwnerDoesNotExist(owner) {
                // If token has owner, revert with error TokenAlreadyExists()
                if owner {
                    mstore(0x00, 0xc991cbb1)
                    revert(0x1c, 0x04)
                }
            }

            function assertOperatorIsOwnerOrApproved(operator, owner, ownershipSlot) {
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
            }

            function assertTransferFromCorrectOwner(from, owner) {
                // If from != owner, revert with error TransferFromIncorrectOwner()
                if iszero(eq(from, owner)) {
                    mstore(0x00, 0xa1148100)
                    revert(0x1c, 0x04)
                }
            }

            function assertRecipientNotAddressZero(recipient) {
                // If to == address(0), revert with error TransferToZeroAddress()
                if iszero(recipient) {
                    mstore(0x00, 0xea553b34)
                    revert(0x1c, 0x04)
                }
            }

            function returnValue(value) {
                mstore(0x00, value)
                return(0x00, 0x20)
            }
        }
    }
}