// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/// @title An proof of concept implementation of the Access Token Protocol
/// @author @0x_Insomnia
/// @notice This implementation should only be used for development
contract AccessTokenERC721 is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter _accessTokenId;

    string validUri;
    string invalidUri;

    ERC721 nftContract;

    mapping(uint => address) accessTokenToOwner;
    mapping(uint => address) granterTokenToOwner;
    mapping(uint => uint) accessTokenToGranterToken;
    mapping(uint => uint) granterTokenToAccessToken;

    /// @param nftContract_ is the NFT contract address you wish to create access tokens for
    constructor(address nftContract_) ERC721("Access Token", "ACCESS") {
        nftContract = ERC721(nftContract_);

        /// @dev _accessTokenId starts counting at 1, use default uint (0) to check against tokens that dont exist
        _accessTokenId.increment();

        /// @dev encode json strings to data urls as: data:text/json;base64
        validUri = encodeJson('{"valid": true}');
        invalidUri = encodeJson('{"valid": false}');
    }

    modifier onlyTokenOwner(uint tokenId) {
        require(
            msg.sender == nftContract.ownerOf(tokenId),
            "caller is not the owner"
        );
        _;
    }

    /// @param nftId is the ID of the NFT you want to create an access token for
    /// @param receiver is the address you wish to mint the access token to
    function create(uint nftId, address receiver) public onlyTokenOwner(nftId) {
        /// @dev revoke access to previous access token if it exists
        uint accessTokenId = granterTokenToAccessToken[nftId];
        if (accessTokenId != 0) {
            revoke(nftId);
        }

        accessTokenToOwner[_accessTokenId.current()] = msg.sender;
        granterTokenToOwner[nftId] = msg.sender;
        accessTokenToGranterToken[_accessTokenId.current()] = nftId;
        granterTokenToAccessToken[nftId] = _accessTokenId.current();

        _safeMint(receiver, _accessTokenId.current());

        _accessTokenId.increment();
    }

    /// @param nftId is the ID of the NFT you want to revoke the access token for
    function revoke(uint nftId) public onlyTokenOwner(nftId) {
        uint accessTokenId = granterTokenToAccessToken[nftId];
        require(accessTokenId != 0, "no access token to revoke");

        accessTokenToOwner[accessTokenId] = address(0);
        granterTokenToOwner[nftId] = address(0);
    }

    /// @param tokenId is the ID of the access token
    function isValid(uint tokenId) external view returns (bool) {
        /// @dev ensures the token has an access token
        if (accessTokenToOwner[tokenId] == address(0)) {
            return false;
        }

        uint granterTokenId = accessTokenToGranterToken[tokenId];

        /// @dev ensure the token still in the wallet that created the access token
        address currentOwner = nftContract.ownerOf(granterTokenId);
        return currentOwner == granterTokenToOwner[granterTokenId];
    }

    /// @param tokenId is the ID of the access token
    /// @return tokenUri data url as: data:text/json;base64
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        uint granterTokenId = accessTokenToGranterToken[tokenId];

        if (granterTokenToOwner[granterTokenId] == address(0)) {
            return invalidUri;
        } else {
            return validUri;
        }
    }

    /// @param json is a json string to be encoded
    function encodeJson(string memory json)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:text/json;base64,",
                    Base64.encode(bytes(abi.encodePacked(json)))
                )
            );
    }

    /// @dev prevent transfers
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("tranfer not allowed");
    }

    /// @dev prevent transfers
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("tranfer not allowed");
    }

    /// @dev prevent transfers
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        revert("tranfer not allowed");
    }
}
