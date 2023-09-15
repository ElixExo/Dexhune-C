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
import { ethers } from "hardhat";

describe("ERC20", function() {
    async function deploy() {
        const DexhuneERC20Factory = await ethers.getContractFactory("DexhuneERC20");

        const DexhuneToken = await DexhuneERC20Factory.deploy();

        return { DexhuneToken };
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

        it ("Should mint 1.4M DXH to exchange each time", async () => {
            const { DexhuneToken } = await loadFixture(deploy);
            const [_, exchangeAddress] = await ethers.getSigners();

            await DexhuneToken.setExchangeAddress(exchangeAddress);

            // for (int i = 0;)



            const res = await DexhuneToken.mintToExchange();



            await expect(res).revertedWithCustomError(DexhuneToken, "PriceDaoAddressNotSet");
        });
    });
});