// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721Solady} from "../compare/ERC721Solady.sol";
import {Brutalizer} from "../utils/Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC721Solady is ERC721Solady, Brutalizer {

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return string(abi.encodePacked("https://remilio.org/remilio/json/", toString(id)));
    }

    function mint(address to, uint256 id) public virtual {
        _mint(_brutalized(to), id);
    }

    function burn(uint256 id) public payable virtual {
        if(!_isApprovedOrOwner(msg.sender, id)) {
            revert NotOwnerNorApproved();
        }
        _burn(id);
    }

    function safeMint(address to, uint256 id) public virtual {
        _safeMint(_brutalized(to), id, "");
    }

    function safeMint(address to, uint256 id, bytes calldata data) public virtual {
        _safeMint(_brutalized(to), id, data);
    }

    function approve(address account, uint256 id) public payable virtual override {
        super.approve(_brutalized(account), id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        super.setApprovalForAll(_brutalized(operator), approved);
    }

    function transferFrom(address from, address to, uint256 id) public payable virtual override {
        super.transferFrom(_brutalized(from), _brutalized(to), id);
    }

    function safeTransferFrom(address from, address to, uint256 id)
        public
        payable
        virtual
        override
    {
        super.safeTransferFrom(_brutalized(from), _brutalized(to), id);
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data)
        public
        payable
        virtual
        override
    {
        super.safeTransferFrom(_brutalized(from), _brutalized(to), id, data);
    }

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits.
            str := add(mload(0x40), 0x80)
            mstore(0x40, add(str, 0x20)) // Allocate the memory.
            mstore(str, 0) // Zeroize the slot after the string.

            let end := str // Cache the end of the memory to calculate the length later.
            let w := not(0) // Tsk.
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for { let temp := value } 1 {} {
                str := add(str, w) // `sub(str, 1)`.
                // Store the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10) // Keep dividing `temp` until zero.
                if iszero(temp) { break }
            }
            let length := sub(end, str)
            str := sub(str, 0x20) // Move the pointer 32 bytes back to make room for the length.
            mstore(str, length) // Store the length.
        }
    }
}