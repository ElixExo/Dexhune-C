// SPDX-License-Identifier: BSD-3-Clause
// Unit Test for Dexhune ERC20Token
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
import { expect } from "chai";
import { ContractTransactionResponse, Mnemonic } from "ethers";
import { ethers } from "hardhat";
import { DexhuneERC20 } from "../typechain-types";

describe("ERC20", function() {
    async function deploy() {
        const DexhuneERC20Factory = await ethers.getContractFactory("DexhuneERC20");

        const DexhuneToken = await DexhuneERC20Factory.deploy();

        return { DexhuneToken };
    }

    async function randomlyAssignFunds(dexhuneToken: DexhuneERC20, signerCount: number) {
        const supply = Number(await dexhuneToken.totalSupply());
        let remSupply = supply;
        const balances = new Map<string, number>();

        const signers = await ethers.getSigners();
        const owner = signers[0];

        for (let i = 1; i < signerCount; i++) {
            const signer = signers[i];
            const balance = Math.floor(Math.random() * remSupply);
            remSupply -= balance;

            // TODO: Cannot transfer to your own address
            await dexhuneToken.transfer(signer.address, balance);
            balances.set(signer.address, balance);                
        }

        balances.set(owner.address, remSupply);
        return balances;
    }

    describe("Deployment", function() {
        it ("Should mint 10M tokens for owner once deployed", async () => {
            const { DexhuneToken } = await loadFixture(deploy);

            const owner = await DexhuneToken.getOwner();
            const res = await DexhuneToken.balanceOf(owner);

            await expect(res).eq(10_000_000);
        });

        it ("Should only allow owner to set initial addresses", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            const [owner, account1, exchangeAddress, daoAddress] = await ethers.getSigners();

            const tokenProxy = DexhuneToken.connect(account1);

            let res = tokenProxy.setExchangeAddress(exchangeAddress);
            await expect(res).to.be.revertedWithCustomError(tokenProxy, "UnauthorizedAccount");

            res = tokenProxy.setDaoAddress(daoAddress);
            await expect(res).to.be.revertedWithCustomError(tokenProxy, "UnauthorizedAccount");
        });

        it ("Should maintain owner until both exchange and dao addresses have been set", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            const [_, exchangeAddress, daoAddress] = await ethers.getSigners();

            await DexhuneToken.setExchangeAddress(exchangeAddress);

            let ownerAddr = await DexhuneToken.getOwner();
            expect(ownerAddr).not.eq("0x000000000000000000000000000000000000dEaD");

            
            const secondFixture = await loadFixture(deploy);

            await secondFixture.DexhuneToken.setDaoAddress(daoAddress);

            ownerAddr = await DexhuneToken.getOwner();
            expect(ownerAddr).not.eq("0x000000000000000000000000000000000000dEaD");
        });

        it ("Should renounce contract after exchange and dao addresses have been set", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            const [_, exchangeAddress, daoAddress] = await ethers.getSigners();

            await DexhuneToken.setExchangeAddress(exchangeAddress);
            await DexhuneToken.setDaoAddress(daoAddress);

            const ownerAddr = await DexhuneToken.getOwner();
            expect(ownerAddr).eq("0x000000000000000000000000000000000000dEaD");
        });
    })

    describe("ERC Standard", function() {
        it ("Should not allow tranfers from an empty wallet", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            const [owner, user1, user2] = await ethers.getSigners();

            const dexhuneToken = await DexhuneToken.connect(user1);

            const res = dexhuneToken.transfer(user2, 1000);
            await expect(res).revertedWithCustomError(dexhuneToken, "InsufficientBalance");
        });

        it ("Should not allow tranfers to the same wallet address", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            const [owner, user1, user2] = await ethers.getSigners();

            DexhuneToken.transfer(user1, 10000);
            const dexhuneToken = await DexhuneToken.connect(user1);

            const res = dexhuneToken.transfer(user1, 1000);
            await expect(res).revertedWithCustomError(dexhuneToken, "DuplicateTransferAddress");
        });

        it ("Accurately transfer funds", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            const [owner, user1, user2] = await ethers.getSigners();

            const supply = await DexhuneToken.totalSupply();
            

            const dexhuneToken = await DexhuneToken.connect(user1);

            for (let i = 0; i < 10; i++) {
                const amount = Math.floor(Math.random() * Number(supply));
                await DexhuneToken.transfer(user1, amount);

                const balance = await DexhuneToken.balanceOf(user1.address);
                expect(balance).eq(amount);

                await dexhuneToken.transfer(owner, amount);
            }
        });

        it ("Should only allow transferFrom based on allowance provided by the user", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            const [owner, user1] = await ethers.getSigners();

            let res = DexhuneToken.transferFrom(owner, user1, 10);
            await expect(res).revertedWithCustomError(DexhuneToken, "NotEnoughAllowance");

            await DexhuneToken.approve(user1, 100);
            
            const dexhuneToken = await DexhuneToken.connect(user1);
            res = dexhuneToken.transferFrom(owner, user1, 10);
            await expect(res).not.be.reverted;

            res = dexhuneToken.transferFrom(owner, user1, 50);
            await expect(res).not.be.reverted;

            res = dexhuneToken.transferFrom(owner, user1, 50);
            await expect(res).revertedWithCustomError(DexhuneToken, "NotEnoughAllowance");

            res = dexhuneToken.transferFrom(owner, user1, 40);
            await expect(res).not.be.reverted;

            res = dexhuneToken.transferFrom(owner, user1, 1);
            await expect(res).revertedWithCustomError(DexhuneToken, "NotEnoughAllowance");
        });
    });

    describe("Minting", function() {
        it ("Should not mint for exchange when exchange address is empty", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            const [_, exchangeAddress, daoAddress] = await ethers.getSigners();

            await DexhuneToken.setDaoAddress(daoAddress);

            const res = DexhuneToken.mintToExchange();
            await expect(res).revertedWithCustomError(DexhuneToken, "ExchangeAddressNotSet");
        });

        it ("Should not mint for PriceDao when PriceDao address is empty", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            const [_, exchangeAddress, daoAddress] = await ethers.getSigners();

            await DexhuneToken.setExchangeAddress(exchangeAddress);

            const res = DexhuneToken.mintToDao();
            await expect(res).revertedWithCustomError(DexhuneToken, "PriceDaoAddressNotSet");
        });

        it ("Should mint 300k DXH to exchange each time", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            const [_, exchangeAddress] = await ethers.getSigners();

            await DexhuneToken.setExchangeAddress(exchangeAddress);

            let nextMintTime = BigInt(0);
            let res: Promise<ContractTransactionResponse>|undefined;

            let minted = BigInt(0);
            let balance = BigInt(0);

            for (let i = 0; i < 100; i++) {
                res = DexhuneToken.mintToExchange();
                await expect(res).to.not.reverted;

                minted += BigInt(300_000);

                balance = await DexhuneToken.balanceOf(exchangeAddress);
                expect(balance).eq(minted);

                nextMintTime = await DexhuneToken.exchangeMintingStartsAfter();
                await time.increase(nextMintTime);
            }
        });

        it ("Should mint 5760 DXH to dao each time", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            const [_, __, daoAddress] = await ethers.getSigners();

            await DexhuneToken.setDaoAddress(daoAddress);

            let nextMintTime = BigInt(0);
            let res: Promise<ContractTransactionResponse>|undefined;

            let minted = BigInt(0);
            let balance = BigInt(0);

            for (let i = 0; i < 100; i++) {
                res = DexhuneToken.mintToDao();
                await expect(res).to.not.reverted;

                minted += BigInt(5760);

                balance = await DexhuneToken.balanceOf(daoAddress);
                expect(balance).eq(minted);

                nextMintTime = await DexhuneToken.daoMintingStartsAfter();
                await time.increase(nextMintTime);
            }
        });

        it ("Should distribute minted funds based on holders percentage", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            
            const signers = await ethers.getSigners();
            const balances = await randomlyAssignFunds(DexhuneToken, 5);

            const exchangeAddr = signers[1].address;

            DexhuneToken.setExchangeAddress(exchangeAddr);

            for (let [addr, value] of balances) {
                const balance = await DexhuneToken.balanceOf(addr);
                expect(Number(balance)).eq(value);
            }

            for (let i = 0; i < 10; i++) {
                const supply = Number(await DexhuneToken.totalSupply());
                
                await DexhuneToken.mint();
                const distribution = Math.floor((Number(supply) * 12) / 10000);
            

                for (let [addr, balance] of balances) {
                    const cut = Math.floor((balance * distribution) / supply);
                    balance += cut;
                    balances.set(addr, balance);

                    const contractBalance = await DexhuneToken.balanceOf(addr);
                    
                    try {
                        expect(Number(contractBalance)).eq(balance);
                    } catch (err) {
                        if (addr == exchangeAddr) {
                            continue; // Exchange gets leftover tokens
                        }

                        console.error(err);
                        throw err;
                    }
                }

                const nextMintTime = await DexhuneToken.mintingStartsAfter();
                await time.increase(nextMintTime);
            }
            
            

            
        });

        it ("Should maintain an accurate supply value", async () => {
            const { DexhuneToken } = await loadFixture(deploy);

            const balances = await randomlyAssignFunds(DexhuneToken, 10);
            const balanceKeys = [...balances.keys()];

            let nextMintTime = BigInt(0);

            for (let i = 0; i < 100; i++) {
                const res = DexhuneToken.mint();
                await expect(res).to.not.reverted;
                
                nextMintTime = await DexhuneToken.mintingStartsAfter();
                await time.increase(nextMintTime);

                const supply = Number(await DexhuneToken.totalSupply());
                let availableSupply = BigInt(0)

                for (let j = 0; j < balances.size; j++) {
                    const addr = balanceKeys[j];

                    const balance = await DexhuneToken.balanceOf(addr);
                    availableSupply += balance;
                }

                expect(supply).eq(availableSupply);
            }
        })

        it ("Should have a mint limit of 3650 and maintain an exponential supply growth", async () => {;
            const { DexhuneToken } = await loadFixture(deploy);
            
            let nextMintTime = BigInt(0);
            let supply = await DexhuneToken.totalSupply();
            let distribution = 0;

            for (let i = 0; i < 3650; i++) {
                const res = DexhuneToken.mint();
                await expect(res).to.not.reverted;

                distribution = Math.floor((Number(supply) * 12) / 10000);
                supply += BigInt(distribution);

                const cSupply = await DexhuneToken.totalSupply();

                expect(cSupply).eq(supply);
            
                nextMintTime = await DexhuneToken.mintingStartsAfter();
                await time.increase(nextMintTime);
            }

            const res = DexhuneToken.mint();
            await expect(res)
                .revertedWithCustomError(DexhuneToken, "MintLimitReached");
        }).timeout(120000);
    });
});