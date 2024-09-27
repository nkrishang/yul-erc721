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

            /*//////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
            //////////////////////////////////////////////////////////////*/

            function selector() -> v {
                v := shr(224, calldataload(0x00))
            }
        }
    }
}