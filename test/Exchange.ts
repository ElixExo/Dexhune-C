// SPDX-License-Identifier: BSD-3-Clause
// Unit Test for Dexhune Exchange
/*
*    ........................................................
*    .%%%%%...%%%%%%..%%..%%..%%..%%..%%..%%..%%..%%..%%%%%%.
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%%.%%..%%.....
*    .%%..%%..%%%%......%%....%%%%%%..%%..%%..%%.%%%..%%%%...
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%..%%..%%.....
*    .%%%%%...%%%%%%..%%..%%..%%..%%...%%%%...%%..%%..%%%%%%.
*    ........................................................
*/

import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { ZeroAddress } from "ethers";
import { MockNFT, MockERC20, DexhuneExchange, MockOracle } from "../typechain-types";

interface Context {
    exchange: DexhuneExchange,
    oracle: MockOracle,
    mockNFT: MockNFT,
    dxh: MockERC20,
    tokens: MockERC20[]
}

describe("Exchange", () => {
    async function deploy(tokenCount = 5): Promise<Context> {
        const ERC20Factory = await ethers.getContractFactory("MockERC20");
        
        const exchange = await (await ethers.getContractFactory("DexhuneExchange")).deploy();
        const oracle = await (await ethers.getContractFactory("MockOracle")).deploy();
        const mockNFT = await (await ethers.getContractFactory("MockNFT")).deploy()
        const dxh = await ERC20Factory.deploy();
        await dxh.setDecimals(0);    
        
        const tokens: MockERC20[] = [dxh];

        for (let i = 0; i < tokenCount; i++) {
            const tk = await ERC20Factory.deploy();
            tokens.push(tk);
        }
        

        return { exchange, oracle, mockNFT, dxh, tokens }
    }

    function deploy40() { return deploy(40); };

    describe("Functionality", async () => {
        it ("Should have an incremental listing price", async () => {
            const [owner] = await ethers.getSigners();
            const { exchange, dxh, tokens } = await loadFixture(deploy40);
            
            let priceProjection = 1000;
            const increaseRatio = (5 / 1000);
            const initialBalance = 1_000_000;

            // Set DXH first
            await exchange.listToken(await dxh.getAddress(), 1, 0, 0, ZeroAddress, "1");
                

            for (let i = 1; i < tokens.length; i++) {
                const tk = tokens[i];
                const addr = await tk.getAddress();

                await dxh.setBalance(owner, initialBalance);
                await exchange.listToken(addr, 1, 0, 0, ZeroAddress, "1");

                const balance = Number(await dxh.balanceOf(owner));
                expect(initialBalance - balance).eq(priceProjection);
                priceProjection += Math.floor((priceProjection * increaseRatio));
            }
        });

        it ("Should correctly calculate relative prices for buy orders", async () => {
            const [owner] = await ethers.getSigners();
            const { exchange, dxh, tokens, oracle } = await loadFixture(deploy);

            const oraclePrice = Math.random() * 99_999;
            await oracle.setPrice(oraclePrice.toFixed(18).toString());
            exchange.assignPriceDao(await oracle.getAddress());
        
            await exchange.listToken(await dxh.getAddress(), 0, 0, 0, ZeroAddress, "1");


            // Note: Allowance is not considered in this test
            const tk = tokens[1];
            const tkAddr = await tk.getAddress();

            const price = Math.random() * 99_999;
            const buyAmount = Math.random() * 999;


            await dxh.setBalance(owner, 10000);
            await exchange.listToken(tkAddr, 0, 0, 0, ZeroAddress, price.toFixed(18).toString());
            
            await tk.setBalance(await owner.getAddress(), 10000);
            await exchange.depositToken(tkAddr, 10000);

            await exchange.createBuyOrder(tkAddr, {
                value: BigInt(buyAmount * 1e18)
            });

            const orderPrice = oraclePrice / price;
            const pending = buyAmount / orderPrice;

            const order = await exchange.viewOrder(tkAddr, 0);
            
            expect((Number(order.price) / 1e18).toFixed(4)).eq(orderPrice.toFixed(4), "Order price is not accurate");
            expect((Number(order.pending) / 1e18).toFixed(4)).eq(pending.toFixed(4), "Pending price is not accurate");
            expect((Number(order.principal) / 1e18).toFixed(4)).eq(buyAmount.toFixed(4), "Principal price is not accurate");
        });
        
        it ("Should correctly calculate relative prices for sell orders", async () => {
            const [owner] = await ethers.getSigners();
            const { exchange, dxh, tokens, oracle } = await loadFixture(deploy);

            const oraclePrice = Math.random() * 99_999;
            await oracle.setPrice(oraclePrice.toFixed(18).toString());
            exchange.assignPriceDao(await oracle.getAddress());
        
            await exchange.listToken(await dxh.getAddress(), 0, 0, 0, ZeroAddress, "1");


            // Note: Allowance is not considered in this test
            const tk = tokens[1];
            const tkAddr = await tk.getAddress();

            const price = Math.random() * 99_999;
            const sellAmount = Math.random() * 999;
            const bigSellAmount = BigInt(sellAmount * 1e18);


            await dxh.setBalance(owner, 10000);
            await exchange.listToken(tkAddr, 0, 0, 0, ZeroAddress, price.toFixed(18).toString());
            
            await tk.setBalance(await owner.getAddress(), bigSellAmount);

            await exchange.createSellOrder(tkAddr, bigSellAmount);

            const orderPrice = oraclePrice / price;
            const pending = sellAmount * orderPrice;

            const order = await exchange.viewOrder(tkAddr, 0);
            
            expect((Number(order.price) / 1e18).toFixed(4)).eq(orderPrice.toFixed(4), "Order price is not accurate");
            expect((Number(order.pending) / 1e18).toFixed(4)).eq(pending.toFixed(4), "Pending price is not accurate");
            expect((Number(order.principal) / 1e18).toFixed(4)).eq(sellAmount.toFixed(4), "Principal price is not accurate");
        });

        it ("Should correctly calculate parity prices for buy orders", async () => {
            const [owner, parityAddr] = await ethers.getSigners();
            const { exchange, dxh, tokens, oracle } = await loadFixture(deploy);

            const oraclePrice = Math.random() * 99_999;
            await oracle.setPrice(oraclePrice.toFixed(18).toString());
            exchange.assignPriceDao(await oracle.getAddress());
        
            await exchange.listToken(await dxh.getAddress(), 0, 0, 0, ZeroAddress, "1");

            // Note: Allowance is not considered in this test
            const tk = tokens[1];
            const tkAddr = await tk.getAddress();

            const tkParityPrice = Math.random() * 99_999;
            const dxhParityPrice = Math.round(Math.random() * 99_999);

            const orderPrice = dxhParityPrice / tkParityPrice;
            const buyAmount = Math.random() * 999;        
            
            await tk.setBalance(parityAddr, BigInt(tkParityPrice * 1e18));
            await dxh.setBalance(parityAddr, BigInt(dxhParityPrice));

            await dxh.setBalance(owner, 10000);
            await exchange.listToken(tkAddr, 1, 0, 0, parityAddr, "0");

            await exchange.createBuyOrder(tkAddr, {
                value: BigInt(buyAmount * 1e18)
            });

            const pending = buyAmount / orderPrice;
            const order = await exchange.viewOrder(tkAddr, 0);
            
            expect((Number(order.price) / 1e18).toFixed(4)).eq(orderPrice.toFixed(4), "Order price is not accurate");
            expect((Number(order.pending) / 1e18).toFixed(4)).eq(pending.toFixed(4), "Pending price is not accurate");
            expect((Number(order.principal) / 1e18).toFixed(4)).eq(buyAmount.toFixed(4), "Principal price is not accurate");
        });

        it ("Should correctly calculate parity prices for sell orders", async () => {
            const [owner, parityAddr] = await ethers.getSigners();
            const { exchange, dxh, tokens, oracle } = await loadFixture(deploy);

            const oraclePrice = Math.random() * 99_999;
            await oracle.setPrice(oraclePrice.toFixed(18).toString());
            exchange.assignPriceDao(await oracle.getAddress());
        
            await exchange.listToken(await dxh.getAddress(), 0, 0, 0, ZeroAddress, "1");

            // Note: Allowance is not considered in this test
            const tk = tokens[1];
            const tkAddr = await tk.getAddress();

            const tkParityPrice = Math.random() * 99_999;
            const dxhParityPrice = Math.round(Math.random() * 99_999);

            const orderPrice = dxhParityPrice / tkParityPrice;
            const sellAmount = Math.random() * 999;    
            const bigSellAmount = BigInt(sellAmount * 1e18);    
            
            await tk.setBalance(parityAddr, BigInt(tkParityPrice * 1e18));
            await dxh.setBalance(parityAddr, BigInt(dxhParityPrice));

            await dxh.setBalance(owner, 10000);
            await exchange.listToken(tkAddr, 1, 0, 0, parityAddr, "0");

            await tk.setBalance(await owner.getAddress(), bigSellAmount);
            await exchange.createSellOrder(tkAddr, bigSellAmount);

            const pending = sellAmount * orderPrice;
            const order = await exchange.viewOrder(tkAddr, 0);
            
            expect((Number(order.price) / 1e18).toFixed(4)).eq(orderPrice.toFixed(4), "Order price is not accurate");
            expect((Number(order.pending) / 1e18).toFixed(4)).eq(pending.toFixed(4), "Pending price is not accurate");
            expect((Number(order.principal) / 1e18).toFixed(4)).eq(sellAmount.toFixed(4), "Principal price is not accurate");
        });

        // it ("Should correctly calculate partial takes for buy orders", async () => {
        //     const [owner, parityAddr] = await ethers.getSigners();
        //     const { exchange, dxh, tokens, oracle } = await loadFixture(deploy);

            


        // });
    })
});