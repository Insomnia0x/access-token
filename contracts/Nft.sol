// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title An example NFT
contract NFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter tokenId;

    constructor() ERC721("NFT", "NFT") {
        /// @dev start counting token ids at 1
        tokenId.increment();
        mint();
    }

    function mint() public {
        _safeMint(msg.sender, tokenId.current());
        tokenId.increment();
    }
}
