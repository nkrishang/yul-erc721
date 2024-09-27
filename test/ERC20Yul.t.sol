// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./utils/YulDeployer.sol";

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface Token is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
}

contract ERC20Test is Test {
    YulDeployer yulDeployer = new YulDeployer();

    Token token;

    function setUp() public {
        token = Token(yulDeployer.deployContract("ERC20"));
    }

    function testExample() public {
        emit log_bytes32(Token.mint.selector);
        
        uint256 x = token.totalSupply();
        emit log_bytes32(bytes32(x));

        x = token.balanceOf(address(this));
        emit log_bytes32(bytes32(x));
        
        // bool suc = token.transfer(address(0x123), 1);

        bytes memory data = abi.encodeWithSignature("mint(address,uint256)", address(this), 5);
        (bool success, bytes memory retData) = address(token).call(data);

        emit log_bytes(data);
        emit log_bytes(retData);

        assertEq(token.balanceOf(address(this)), 5);
    }
}

// 0x6100093415610398565b6100116101ce565b806370a082311461011857806318160ddd1461010
// b578063a9059cbb146100eb57806323b872dd146100c1578063095ea7b3146100a1578063dd62ed
// 3e14610081576340c10f1914610061575f80fd5b61007c61006e60016101f7565b6100775f6101d9
// 565b61012e565b610216565b61009c61008e60016101d9565b6100975f6101d9565b610325565b61