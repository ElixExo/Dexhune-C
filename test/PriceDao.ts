// SPDX-License-Identifier: BSD-3-Clause
// Unit Test for Dexhune PriceDao
/*
*    ........................................................
*    .%%%%%...%%%%%%..%%..%%..%%..%%..%%..%%..%%..%%..%%%%%%.
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%%.%%..%%.....
*    .%%..%%..%%%%......%%....%%%%%%..%%..%%..%%.%%%..%%%%...
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%..%%..%%.....
*    .%%%%%...%%%%%%..%%..%%..%%..%%...%%%%...%%..%%..%%%%%%.
*    ........................................................
*/

import { loadFixture, mine, mineUpTo, time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { DexhunePriceDAO, MockNFT } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ContractTransactionReceipt } from "ethers";

const REWARD_MULTIPLIER = 20

describe("PriceDAO", function() {
    async function deploy() {
        const [owner] = await ethers.getSigners();
        
        const MockNFTFactory = await ethers.getContractFactory("MockNFT");
        const ERC20Factory = await ethers.getContractFactory("MockERC20");
        const DexhunePriceDaoFactory = await ethers.getContractFactory("DexhunePriceDAO");
        
        const MockNFT = await MockNFTFactory.deploy();
        const ERC20 = await ERC20Factory.deploy();
        const PriceDao = await DexhunePriceDaoFactory.deploy();

        await PriceDao.assignNFTCollection(await MockNFT.getAddress());

        return { PriceDao, MockNFT, owner, ERC20 }; 
    }

    async function proposeFirstPrice(dao: DexhunePriceDAO, mockNft: MockNFT, owner: HardhatEthersSigner) {
        const desc = "First price";
        const price = "Your mom";

        await mockNft.mint(owner.address);

        return dao.proposePrice(price, desc);
    }

    async function proposeAndVote(dao: DexhunePriceDAO, mockNft: MockNFT, owner: HardhatEthersSigner) {
        const res = mockNft.mint(owner.address);
        await expect(res).to.not.be.reverted;

        await proposeFirstPrice(dao, mockNft, owner);
    }

    async function voteUp(address: HardhatEthersSigner, amount: number, mockNFT: MockNFT, priceDAO: DexhunePriceDAO) {
        await mockNFT.mintAmount(address, amount);
        
        priceDAO = await priceDAO.connect(address);
        await priceDAO.voteUp();
    }

    async function voteDown(address: HardhatEthersSigner, amount: number, mockNFT: MockNFT, priceDAO: DexhunePriceDAO) {
        await mockNFT.mintAmount(address, amount);
        
        priceDAO = await priceDAO.connect(address);
        await priceDAO.voteDown();
    }

    // async function simulateVoteFor(dao: DexhunePriceDAO, mockNft: MockNFT) {
    //     const signers = await ethers.getSigners();
        
    //     for (let i = 0; i < signers.length; i++) {
    //         const signer = signers[i];

    //         await mockNft.mint(signer.address);
    //         await dao.connect(signer).voteUp();
    //     }

    //     const latest = await dao.latestProposal();
    //     expect(latest.votesUp).eq(signers.length);
    // }

    // async function simulateVoteAgainst(dao: DexhunePriceDAO, mockNft: MockNFT) {
    //     const signers = await ethers.getSigners();
        
    //     for (let i = 0; i < signers.length; i++) {
    //         const signer = signers[i];

    //         await mockNft.mint(signer.address);
    //         await dao.connect(signer).voteDown();
    //     }

    //     const latest = await dao.latestProposal();
    //     expect(latest.votesDown).eq(signers.length);
    // }

    describe("Deployment", function() {
        it ("Should correctly create proposals", async function() {
            const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

            const desc = "First price";
            const price = "Your mom";

            await proposeFirstPrice(PriceDao, MockNFT, owner);

            const latest = await PriceDao.latestProposal();
            
            expect(latest.description).to.eq(desc);
            expect(latest.value).to.eq(price);            
        });

        it ("Should not allow multiple proposals at a time", async () => {
            const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

            await proposeFirstPrice(PriceDao, MockNFT, owner);

            const desc = "Second price";
            const price = "1000";

            const res = PriceDao.proposePrice(desc, price);
            await expect(res).to.be
                .revertedWithCustomError(PriceDao, "ProposalIsStillActive");
        });

        it ("Should not allow proposal finalize before voting deadline", async () => {
            const { PriceDao, MockNFT, owner, ERC20 } = await loadFixture(deploy);

            await ERC20.setBalance(await PriceDao.getAddress(), 20);
            await PriceDao.assignTokenAddress(await ERC20.getAddress());


            await proposeFirstPrice(PriceDao, MockNFT, owner);

            let res = MockNFT.mint(owner.address);
            await expect(res).to.not.be.reverted;

            await time.increase(10);
    
            res = PriceDao.finalizeProposal();
            await expect(res).to.revertedWithCustomError(PriceDao, "ProposalIsStillActive");
        });

        it ("Should allow proposal finalize after voting deadline", async () => {
            const { PriceDao, MockNFT, owner, ERC20 } = await loadFixture(deploy);
            
            await ERC20.setBalance(await PriceDao.getAddress(), 20);
            await PriceDao.assignTokenAddress(await ERC20.getAddress());


            await proposeFirstPrice(PriceDao, MockNFT, owner);

            let res = MockNFT.mint(owner.address);
            await expect(res).to.not.be.reverted;

            await PriceDao.voteUp();

            const deadline = await PriceDao.votingEndsAfter();

            await time.increase(deadline);

            res = PriceDao.finalizeProposal();
            await expect(res).to.not.reverted;
        });

        it ("Proposer should be rewarded correctly", async () => {
            const { PriceDao, MockNFT, ERC20 } = await loadFixture(deploy);
            const [ owner, user2, user3, user4 ] = await ethers.getSigners();
            
            await ERC20.setBalance(await PriceDao.getAddress(), 999999);
            await PriceDao.assignTokenAddress(await ERC20.getAddress());

            const ownerDAO = PriceDao.connect(owner);
            await proposeFirstPrice(ownerDAO, MockNFT, owner);

            await voteUp(user4, 30, MockNFT, PriceDao);
            await voteDown(user2, 34, MockNFT, PriceDao);
            await voteUp(user3, 20, MockNFT, PriceDao);

            const totalVotes = 30 + 34 + 20;
            const reward = totalVotes * REWARD_MULTIPLIER;

            const deadline = await PriceDao.votingEndsAfter();

            await time.increase(deadline);

            await PriceDao.finalizeProposal();
            
            const res = await ERC20.balanceOf(owner);
            expect(res).eq(reward);
        });

        // it ("Should not allow non eligible proposers", async () => {
        //     const { PriceDao } = await loadFixture(deploy);

        //     await proposeFirstPrice(PriceDao);

        //     const res = PriceDao.voteUp();
        //     await expect(res).to.be
        //         .revertedWithCustomError(PriceDao, "NotEligible");
        // });

        it ("Should not allow non eligible voters", async () => {
            const { PriceDao, MockNFT } = await loadFixture(deploy);
            const [ owner, user2 ] = await ethers.getSigners();

            await proposeFirstPrice(PriceDao, MockNFT, owner);

            const dao = PriceDao.connect(user2);

            const res = dao.voteUp();
            await expect(res).to.be
                .revertedWithCustomError(dao, "NotEligible");
        });

        it ("Should allow eligible voters", async () => {
            const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

            await proposeFirstPrice(PriceDao, MockNFT, owner);

            let res = MockNFT.mint(owner.address);
            await expect(res).to.not.be.reverted;

            res = PriceDao.voteUp();
            await expect(res).to.not.be.reverted;
        });

        it ("Should not allow voting twice", async () => {
            const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

            await proposeFirstPrice(PriceDao, MockNFT, owner);

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

            await proposeFirstPrice(PriceDao, MockNFT, owner);

            let res = MockNFT.mint(owner.address);
            await expect(res).to.not.be.reverted;

            res = PriceDao.voteDown();
            await expect(res).to.not.be.reverted;

            res = PriceDao.voteUp();
            await expect(res).to.be.revertedWithCustomError(PriceDao, "AlreadyVoted");

            res = PriceDao.voteDown();
            await expect(res).to.be.revertedWithCustomError(PriceDao, "AlreadyVoted");
        });

        // it ("Should not allow voting past the voting deadline", async () => {
        //     const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

        //     await proposeAndVote(PriceDao, MockNFT, owner);
        //     const votingDeadline = (await PriceDao.votingEndsAfter());
            
        //     await time.advanceBlockTo(votingDeadline);
        //     const res = PriceDao.voteUp();
        //     await expect(res).to.be.revertedWithCustomError(PriceDao, "VotingDeactivated");
        // });

        // it ("Should not finalize while voting is active", async () => {
        //     const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

        //     await proposeAndVote(PriceDao, MockNFT, owner);
            
        //     const votingDeadline = (await PriceDao.votingEndsAt());
        //     const almostThere = Math.round(Number(votingDeadline) * .9);


        //     await time.advanceBlockTo(almostThere);

        //     const res = PriceDao.finalizeProposal();
        //     await expect(res).to.be
        //         .revertedWithCustomError(PriceDao, "ProposalIsStillActive");
        // });

        // it ("Should not finalize after deadline", async () => {
        //     const { PriceDao, MockNFT, owner } = await loadFixture(deploy);

        //     await proposeAndVote(PriceDao, MockNFT, owner);
            
        //     const deadline = (await PriceDao.proposalExpiresAt());          
        //     await time.advanceBlockTo(deadline);

        //     const res = PriceDao.finalizeProposal();
        //     await expect(res).to.be
        //         .revertedWithCustomError(PriceDao, "ProposalHasExpired");
        // });

        // it ("Should change the price after a proposal has voted for and finalized", async () => {
        //     const { PriceDao, MockNFT } = await loadFixture(deploy);

        //     await proposeFirstPrice(PriceDao);

        //     await simulateVoteFor(PriceDao, MockNFT);
            
        //     const votingDeadline = (await PriceDao.votingEndsAt());          
        //     await time.advanceBlockTo(votingDeadline);

        //     const res = PriceDao.finalizeProposal();
        //     await expect(res).to.not.be.reverted;

        //     const price = await PriceDao.getPrice();
        //     expect(price).to.eq("Your mom");
        // });

        // it ("Should not change the price if the proposal was rejected", async () => {
        //     const { PriceDao, MockNFT } = await loadFixture(deploy);

        //     let price = await PriceDao.getPrice();
        //     await proposeFirstPrice(PriceDao);

        //     await simulateVoteAgainst(PriceDao, MockNFT);
            
        //     const votingDeadline = (await PriceDao.votingEndsAt());          
        //     await time.advanceBlockTo(votingDeadline);

        //     const res = PriceDao.finalizeProposal();
        //     await expect(res).to.not.be.reverted;

        //     const newPrice = await PriceDao.getPrice();
        //     expect(price).to.eq(newPrice);
        // });
    })
});