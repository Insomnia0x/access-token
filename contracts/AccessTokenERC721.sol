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

    ERC721 token;

    mapping(uint => address) accessTokenToOwner;
    mapping(uint => address) granterTokenToOwner;
    mapping(uint => uint) accessTokenToGranterToken;
    mapping(uint => uint) granterTokenToAccessToken;

    /// @param token_ is the address of the token contract you wish to create access tokens for
    constructor(address token_) ERC721("Access Token", "ACCESS") {
        token = ERC721(token_);

        /// @dev _accessTokenId starts counting at 1, use default uint (0) to check against tokens that dont exist
        _accessTokenId.increment();

        /// @dev encode json strings to data urls as: data:text/json;base64
        validUri = encodeJson('{"valid": true}');
        invalidUri = encodeJson('{"valid": false}');
    }

    modifier onlyTokenOwner(uint tokenId) {
        require(
            msg.sender == token.ownerOf(tokenId),
            "caller is not the owner"
        );
        _;
    }

    /// @param granterTokenId is the ID of the token you want to create an access token for
    /// @param receiver is the address you wish to mint the access token to
    function createAccessToken(uint granterTokenId, address receiver)
        public
        onlyTokenOwner(granterTokenId)
    {
        /// @dev revoke access to previous access token if it exists
        uint accessTokenId = granterTokenToAccessToken[granterTokenId];
        if (accessTokenId != 0) {
            revokeAccess(granterTokenId);
        }

        accessTokenToOwner[_accessTokenId.current()] = msg.sender;
        granterTokenToOwner[granterTokenId] = msg.sender;
        accessTokenToGranterToken[_accessTokenId.current()] = granterTokenId;
        granterTokenToAccessToken[granterTokenId] = _accessTokenId.current();

        _safeMint(receiver, _accessTokenId.current());

        _accessTokenId.increment();
    }

    /// @param granterTokenId is the ID of the token you want to revoke the access token for
    function revokeAccess(uint granterTokenId)
        public
        onlyTokenOwner(granterTokenId)
    {
        uint accessTokenId = granterTokenToAccessToken[granterTokenId];
        require(accessTokenId != 0, "no access token to revoke");

        accessTokenToOwner[accessTokenId] = address(0);
        granterTokenToOwner[granterTokenId] = address(0);
    }

    /// @param accessTokenId is the ID of the access token
    function isValid(uint accessTokenId) external view returns (bool) {
        /// @dev ensures the token has an access token
        if (accessTokenToOwner[accessTokenId] == address(0)) {
            return false;
        }

        uint granterTokenId = accessTokenToGranterToken[accessTokenId];

        /// @dev ensure the token still in the wallet that created the access token
        address currentOwner = token.ownerOf(granterTokenId);
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
