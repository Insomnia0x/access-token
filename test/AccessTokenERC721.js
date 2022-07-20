const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("AccessTokenERC721 Tests", function () {
    async function deployFixture() {
        const nftFactory = await ethers.getContractFactory("NFT");
        const nft = await nftFactory.deploy();

        const accessTokenERC721Factory = await ethers.getContractFactory(
            "AccessTokenERC721"
        );
        const accessErc721 = await accessTokenERC721Factory.deploy(nft.address);

        const [owner, ...accounts] = await ethers.getSigners();

        return { nft, accessErc721, owner, accounts };
    }

    describe("createAccessToken tests", function () {
        it("Should revert when sender is not the token owner", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await expect(
                accessErc721
                    .connect(accounts[0])
                    .createAccessToken(1, accounts[1].address)
            ).to.be.revertedWith("caller is not the owner");
        });

        it("Should revert when tokenId does not exist", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await expect(
                accessErc721.createAccessToken(99999, owner.address)
            ).to.be.revertedWith("ERC721: invalid token ID");
        });

        it("Should revoke access to a previous access token when creating a new one", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await accessErc721.createAccessToken(1, owner.address);
            expect(await accessErc721.isValid(1)).to.equal(true);

            await accessErc721.createAccessToken(1, owner.address);
            expect(await accessErc721.isValid(1)).to.equal(false);
            expect(await accessErc721.isValid(2)).to.equal(true);
        });

        it("Should create a valid access token", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await accessErc721.createAccessToken(1, owner.address);

            expect(await accessErc721.isValid(1)).to.equal(true);
        });
    });

    describe("isValid tests", function () {
        it("Should return false when given an access token that does not exist", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            expect(await accessErc721.isValid(0)).to.equal(false);
        });

        it("Should return false when given an access token that has been revoked", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await accessErc721.createAccessToken(1, owner.address);
            expect(await accessErc721.isValid(1)).to.equal(true);
            await accessErc721.revokeAccess(1);

            expect(await accessErc721.isValid(1)).to.equal(false);
        });

        it("Should return false when parent token has been transferred from the original owner", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await accessErc721.createAccessToken(1, owner.address);
            expect(await accessErc721.isValid(1)).to.equal(true);

            await nft["safeTransferFrom(address,address,uint256)"](
                owner.address,
                accounts[0].address,
                1
            );

            expect(await accessErc721.isValid(1)).to.equal(false);
        });
    });

    describe("revokeAccess tests", function () {
        it("Should revert when sender is not the token owner", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await accessErc721.createAccessToken(1, owner.address);

            await expect(
                accessErc721.connect(accounts[0]).revokeAccess(1)
            ).to.be.revertedWith("caller is not the owner");
        });

        it("Should revert when granter token does not exist", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await accessErc721.createAccessToken(1, owner.address);

            await expect(accessErc721.revokeAccess(9999)).to.be.revertedWith(
                "ERC721: invalid token ID"
            );
        });

        it("Should revert when access token does not exist", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await accessErc721.createAccessToken(1, owner.address);
            await nft.mint();

            await expect(accessErc721.revokeAccess(2)).to.be.revertedWith(
                "no access token to revoke"
            );
        });
    });

    describe("tokenURI tests", function () {
        it("Should return false when access token does not exist", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            expect(await accessErc721.tokenURI(9999)).to.equal(
                "data:text/json;base64,eyJ2YWxpZCI6IGZhbHNlfQ=="
            );
        });

        it("Should return false when access has been revoked", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await accessErc721.createAccessToken(1, owner.address);
            expect(await accessErc721.isValid(1)).to.equal(true);

            await accessErc721.revokeAccess(1);
            expect(await accessErc721.isValid(1)).to.equal(false);

            expect(await accessErc721.tokenURI(1)).to.equal(
                "data:text/json;base64,eyJ2YWxpZCI6IGZhbHNlfQ=="
            );
        });

        it("Should return true when access token is valid", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await accessErc721.createAccessToken(1, owner.address);
            expect(await accessErc721.isValid(1)).to.equal(true);

            expect(await accessErc721.tokenURI(1)).to.equal(
                "data:text/json;base64,eyJ2YWxpZCI6IHRydWV9"
            );
        });
    });

    describe("prevent transfer tests", function () {
        it("Should revert when transferFrom is called", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await accessErc721.createAccessToken(1, owner.address);
            await expect(
                accessErc721.transferFrom(owner.address, accounts[0].address, 1)
            ).to.be.revertedWith("tranfer not allowed");
        });

        it("Should revert when safeTransferFrom is called", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await accessErc721.createAccessToken(1, owner.address);
            await expect(
                accessErc721["safeTransferFrom(address,address,uint256)"](
                    owner.address,
                    accounts[0].address,
                    1
                )
            ).to.be.revertedWith("tranfer not allowed");
        });

        it("Should revert when safeTransferFrom (with data) is called", async function () {
            const { nft, accessErc721, owner, accounts } = await loadFixture(
                deployFixture
            );

            await accessErc721.createAccessToken(1, owner.address);
            await expect(
                accessErc721["safeTransferFrom(address,address,uint256,bytes)"](
                    owner.address,
                    accounts[0].address,
                    1,
                    "0x"
                )
            ).to.be.revertedWith("tranfer not allowed");
        });
    });
});
