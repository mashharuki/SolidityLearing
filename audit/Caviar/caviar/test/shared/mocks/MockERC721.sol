// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/tokens/ERC721.sol";

contract MockERC721 is ERC721 {
    string public baseURI = "yeet";

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mint(address to, uint256 id) public {
        _mint(to, id);
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return baseURI;
    }
}
