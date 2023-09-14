// SPDX-License-Identifier: BSD-3-Clause
// Unit Test for PriceDao
/*
*    ........................................................
*    .%%%%%...%%%%%%..%%..%%..%%..%%..%%..%%..%%..%%..%%%%%%.
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%%.%%..%%.....
*    .%%..%%..%%%%......%%....%%%%%%..%%..%%..%%.%%%..%%%%...
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%..%%..%%.....
*    .%%%%%...%%%%%%..%%..%%..%%..%%...%%%%...%%..%%..%%%%%%.
*    ........................................................
*/

import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { expect, use } from "chai";
import { ethers } from "hardhat";
import { DexhunePriceDAO, MockNFT } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("PriceDao", function() {
    async function deploy() {
        const [owner] = await ethers.getSigners();
        
        const MockNFTFactory = await ethers.getContractFactory("MockNFT");
        const DexhunePriceDaoFactory = await ethers.getContractFactory("DexhunePriceDAO");
        
        const MockNFT = await MockNFTFactory.deploy();
        const PriceDao = await DexhunePriceDaoFactory.deploy();

        const addr = await MockNFT.getAddress();
                
        const res = await PriceDao.addNFTCollection(addr);
        expect(res).not.reverted;

        return { PriceDao, MockNFT, owner }; 
    }

    function proposeFirstPrice(dao: DexhunePriceDAO) {
        const desc = "First price";
        const price = "Your mom";

        return dao.proposePrice(desc, price);
    }

    async function proposeAndVote(dao: DexhunePriceDAO, mockNft: MockNFT, owner: HardhatEthersSigner) {
        const res = mockNft.mint(owner.address);
        await expect(res).to.not.be.reverted;

        await proposeFirstPrice(dao);
    }

    async function simulateVoteFor(dao: DexhunePriceDAO, mockNft: MockNFT) {
        const signers = await ethers.getSigners();
        
        for (let i = 0; i < signers.length; i++) {
            const signer = signers[i];

            await mockNft.mint(signer.address);
            await dao.connect(signer).voteUp();
        }

        const current = await dao.currentProposal();
        expect(current.votesUp).eq(signers.length);
    }

    async function simulateVoteAgainst(dao: DexhunePriceDAO, mockNft: MockNFT) {
        const signers = await ethers.getSigners();
        
        for (let i = 0; i < signers.length; i++) {
            const signer = signers[i];

            await mockNft.mint(signer.address);
            await dao.connect(signer).voteDown();
        }

        const current = await dao.currentProposal();
        expect(current.votesDown).eq(signers.length);
    }

    describe("Deployment", function() {
        it ("Should correctly create proposals", async function() {
            const { PriceDao } = await loadFixture(deploy);

            const desc = "First price";
            const price = "Your mom";

            await proposeFirstPrice(PriceDao);

            const current = await PriceDao.currentProposal();
            
            expect(current.description).to.eq(desc);
            expect(current.value).to.eq(price);            
        });

        it ("Should not allow multple proposals at a time", async () => {
            const { PriceDao } = await loadFixture(deploy);

            await proposeFirstPrice(PriceDao);

            const desc = "Second price";
            const price = "1000";

            const res = PriceDao.proposePrice(desc, price);
            await expect(res).to.be
                .revertedWithCustomError(PriceDao, "ProposalIsStillActive");
        });

        it ("Should not allow non eligible voters", async () => {
            const { PriceDao } = await loadFixture(deploy);

            await proposeFirstPrice(PriceDao);

            const res = PriceDao.voteUp();
            await expect(res).to.be
                .revertedWithCustomError(PriceDao, "NotEligibleToVote");
        });

        it ("Should allow eligible voters", async () => {
            const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

            await proposeFirstPrice(PriceDao);

            let res = MockNFT.mint(owner.address);
            await expect(res).to.not.be.reverted;

            res = PriceDao.voteUp();
            await expect(res).to.not.be.reverted;
        });

        it ("Should not allow voting twice", async () => {
            const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

            await proposeFirstPrice(PriceDao);

            let res = MockNFT.mint(owner.address);
            await expect(res).to.not.be.reverted;

            res = PriceDao.voteUp();
            await expect(res).to.not.be.reverted;

            res = PriceDao.voteDown();
            await expect(res).to.be.revertedWithCustomError(PriceDao, "AlreadyVoted");

            res = PriceDao.voteUp();
            await expect(res).to.be.revertedWithCustomError(PriceDao, "AlreadyVoted");
        });

        it ("Should not allow voting twice (inverted order)", async () => {
            const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

            await proposeFirstPrice(PriceDao);

            let res = MockNFT.mint(owner.address);
            await expect(res).to.not.be.reverted;

            res = PriceDao.voteDown();
            await expect(res).to.not.be.reverted;

            res = PriceDao.voteUp();
            await expect(res).to.be.revertedWithCustomError(PriceDao, "AlreadyVoted");

            res = PriceDao.voteDown();
            await expect(res).to.be.revertedWithCustomError(PriceDao, "AlreadyVoted");
        });

        it ("Should not allow voting past the voting deadline", async () => {
            const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

            await proposeAndVote(PriceDao, MockNFT, owner);
            const votingDeadline = (await PriceDao.votingEndsAt());
            
            await time.advanceBlockTo(votingDeadline);
            const res = PriceDao.voteUp();
            await expect(res).to.be.revertedWithCustomError(PriceDao, "VotingDeactivated");
        });

        it ("Should not finalize while voting is active", async () => {
            const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

            await proposeAndVote(PriceDao, MockNFT, owner);
            
            const votingDeadline = (await PriceDao.votingEndsAt());
            const almostThere = Math.round(Number(votingDeadline) * .9);


            await time.advanceBlockTo(almostThere);

            const res = PriceDao.finalizeProposal();
            await expect(res).to.be
                .revertedWithCustomError(PriceDao, "ProposalIsStillActive");
        });

        it ("Should not finalize after deadline", async () => {
            const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

            await proposeAndVote(PriceDao, MockNFT, owner);
            
            const deadline = (await PriceDao.proposalExpiresAt());          
            await time.advanceBlockTo(deadline);

            const res = PriceDao.finalizeProposal();
            await expect(res).to.be
                .revertedWithCustomError(PriceDao, "ProposalHasExpired");
        });

        it ("Should change the price after a proposal has voted for and finalized", async () => {
            const { PriceDao, MockNFT } = await loadFixture(deploy);

            await proposeFirstPrice(PriceDao);

            await simulateVoteFor(PriceDao, MockNFT);
            
            const votingDeadline = (await PriceDao.votingEndsAt());          
            await time.advanceBlockTo(votingDeadline);

            const res = PriceDao.finalizeProposal();
            await expect(res).to.not.be.reverted;

            const price = await PriceDao.getPrice();
            expect(price).to.eq("Your mom");
        });

        it ("Should not change the price if the proposal was rejected", async () => {
            const { PriceDao, MockNFT } = await loadFixture(deploy);

            let price = await PriceDao.getPrice();
            await proposeFirstPrice(PriceDao);

            await simulateVoteAgainst(PriceDao, MockNFT);
            
            const votingDeadline = (await PriceDao.votingEndsAt());          
            await time.advanceBlockTo(votingDeadline);

            const res = PriceDao.finalizeProposal();
            await expect(res).to.not.be.reverted;

            const newPrice = await PriceDao.getPrice();
            expect(price).to.eq(newPrice);
        });
    })
})