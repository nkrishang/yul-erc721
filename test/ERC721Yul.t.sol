// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./utils/YulDeployer.sol";
import { MockERC721InlineAssembly as Token } from "./mock/MockERC721InlineAssembly.sol";

contract ERC721YulTest is Test {
    YulDeployer yulDeployer = new YulDeployer();

    Token public token;

    function setUp() public {
        token = Token(yulDeployer.deployContract("ERC721"));
    }

    function testExample() public {
        assertEq(token.name(), "TEST NFT");
    }
}