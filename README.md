# Access Token Protocol

** This is a proof of concept and a work in progress **

### The Problem:

Tokens may grant users access to token gated content. Users want to keep their tokens safe, but also access these services in a convenient manner.

Keeping tokens in a safe place provides security at the expense of convenience. A user should not have to compromise their security in order to access token gated content.

### The Solution:

The access token protocol aims to provide a way for users to keep their prized tokens locked away safely while still having access to token gated content in a convenient way.

An ERC-721 access token can be minted to any wallet - granting that wallet access to the token gated content - provided the project is using the access token protocol.

The access token protocol can be added to any existing project.

The access token will be valid until:

-   The owner revokes access
-   The “granter” token is transferred from the owners wallet

### How It Works

-   The owner mints an access token to any wallet they choose
-   The access token is bound to the “granter” token (the NFT, or ERC-20, etc)
-   A dapp can use the Access Token Protocol
-   Access tokens can be revoked by the owner, and access tokens become invalid when the granted token leaves the owners wallet

### TODO

-   Create an interface when the API is determined
-   Create an abstract base class
-   Create implementations for ERC-721, 20, and other common tokens, as well as use cases (minimum balance for example)
-   Create demo contracts & dapp
