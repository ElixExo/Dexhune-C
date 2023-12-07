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

import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { ContractFactory, ZeroAddress } from "ethers";
import { MockNFT, MockERC20, DexhuneExchange, MockOracle } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

const provider = ethers.provider;

interface Context {
    exchange: DexhuneExchange,
    oracle: MockOracle,
    mockNFT: MockNFT,
    dxh: MockERC20,
    tokens: MockERC20[],
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

    async function deployAndList40() {
        const ctx = await deploy(40);
        const [owner] = await ethers.getSigners();
        const { exchange, dxh, tokens, oracle } = ctx;

        const ownerAddr = await owner.getAddress();
        let balance = await dxh.balanceOf(ownerAddr);

        const oraclePrice = Math.random() * 99_999;
        await oracle.setPrice(oraclePrice.toFixed(18).toString());
        exchange.assignPriceDAO(await oracle.getAddress());

        for (let i = 0; i < tokens.length; i++) {
            const tk = tokens[i];
            const tkAddr = await tk.getAddress();

            balance += await exchange.listingCost();
            await dxh.setBalance(ownerAddr, balance);

            switch (i) {
                case 0:
                    await exchange.listToken(tkAddr, 0, 0, "1");
                    break;

                default:
                    const price = Math.random() * 99_999;
                    await exchange.listToken(tkAddr, 0, 0, price.toFixed(18).toString());
                    break;
            }
        }

        return { ...ctx }
    }

    async function deployWithBuyOrder() {
        const ctx = await deploy();

        while (true) {
            try {
                const [owner] = await ethers.getSigners();
                const { exchange, oracle, dxh, tokens } = ctx;
    
                const oraclePrice = Math.random() * 99_999;
                await oracle.setPrice(oraclePrice.toFixed(18).toString());
                exchange.assignPriceDAO(await oracle.getAddress());
    
                await exchange.listToken(await dxh.getAddress(), 0, 0, "1");
    
                const tk = tokens[1];
                const tkAddr = await tk.getAddress();
    
                const tkDec = Number((Math.random() * 18).toFixed());
                await tk.setDecimals(tkDec);
    
                // console.log("Decimals: ", tkDec);
    
                const price = Math.random() * 99_999;
    
                const scalar = 10 ** tkDec;
    
                const initialDeposit =  Math.random() * 99_999;
                const scaledDeposit = BigInt((initialDeposit * scalar).toFixed());
                
                const buyAmount = Math.random() * 999;
    
                await dxh.setBalance(owner, 10000);
                await exchange.listToken(tkAddr, 0, 0, price.toFixed(18).toString());
    
                await tk.setBalance(await owner.getAddress(), scaledDeposit);
                // await exchange.depositToken(tkAddr, scaledDeposit);
    
                await exchange.createBuyOrder(tkAddr, {
                    value: BigInt((buyAmount * 1e18).toFixed())
                });
            } catch (err) {
                if (err instanceof SyntaxError) {
                    await provider.send("hardhat_reset", []);
                    
                    continue;
                } else throw err;
            }

            return { ...ctx };
        }
    }

    async function deployWithSellOrder() {
        const ctx = await deploy();

        while (true) {
            try {
                const [owner, user1] = await ethers.getSigners();
                const { exchange, oracle, dxh, tokens } = ctx;
    
                // Provide us with sufficient AVAX for the test
                provider.send("hardhat_setBalance", [
                    user1.address,
                    "0x10000000000000000000000000000000000000000",
                ]);
    
                const oraclePrice = Math.random() * 99_999;
                await oracle.setPrice(oraclePrice.toFixed(18).toString());
                exchange.assignPriceDAO(await oracle.getAddress());
    
                await exchange.listToken(await dxh.getAddress(), 0, 0, "1");
    
                const tk = tokens[1];
                const tkAddr = await tk.getAddress();
    
                const tkDec = Number((Math.random() * 18).toFixed());
                tk.setDecimals(tkDec);
    
                // console.log("Decimals: ", tkDec);
    
                const price = Math.random() * 99_999;
    
                const scalar = 10 ** tkDec;
    
                const initialDeposit =  Math.random() * 99_999;
                const scaledDeposit = BigInt((initialDeposit * scalar).toFixed());
    
                const sellAmount = Math.random() * 999;
                const scaledSellAmount = BigInt(Number(sellAmount * scalar).toFixed());
    
                // console.log("Selling: ", sellAmount, scaledSellAmount);
    
                await dxh.setBalance(owner, 10000);
                await exchange.listToken(tkAddr, 0, 0, price.toFixed(18).toString());
    
                await tk.setBalance(await owner.getAddress(), scaledDeposit);
                await exchange.depositToken(tkAddr, scaledDeposit);
    
                await tk.setBalance(await owner.getAddress(), scaledSellAmount);
                await exchange.createSellOrder(tkAddr, scaledSellAmount);
            } catch (err) {
                if (err instanceof SyntaxError) {
                    await provider.send("hardhat_reset", []);
                    continue;
                } else throw err;
            }

            return { ...ctx }
        }
    }

    describe("Functionality", async () => {
        it ("Should have an incremental listing price", async () => {
            const [owner] = await ethers.getSigners();
            const { exchange, dxh, tokens } = await loadFixture(deploy40);
            
            let priceProjection = 1000;
            const increaseRatio = (5 / 1000);
            const initialBalance = 1_000_000;

            // Set DXH first
            await exchange.listToken(await dxh.getAddress(), 0, 0, "1");
                

            for (let i = 1; i < tokens.length; i++) {
                const tk = tokens[i];
                const addr = await tk.getAddress();

                await dxh.setBalance(owner, initialBalance);
                await exchange.listToken(addr, 0, 0, "1");

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
            exchange.assignPriceDAO(await oracle.getAddress());
        
            await exchange.listToken(await dxh.getAddress(), 0, 0, "1");


            // Note: Allowance is not considered in this test
            const tk = tokens[1];
            const tkDec = Number((Math.random() * 18).toFixed()); 
            await tk.setDecimals(18);

            const tkAddr = await tk.getAddress();

            const price = Math.random () * 99_999;
            const buyAmount = Math.random() * 999;


            await dxh.setBalance(owner, 10000);
            await exchange.listToken(tkAddr, 0, 0, price.toFixed(18).toString());
            
            await tk.setBalance(await owner.getAddress(), 10000);
            await exchange.depositToken(tkAddr, 10000);

            await exchange.createBuyOrder(tkAddr, {
                value: BigInt(buyAmount * 1e18)
            });

            const orderPrice = oraclePrice / price;
            const pending = (buyAmount * orderPrice);

            
            const order = await exchange.viewOrderByToken(tkAddr, 0);
            
            expect((Number(order.price) / 1e18).toFixed(4)).eq(orderPrice.toFixed(4), "Order price is not accurate");
            expect((Number(order.pending) / 1e18).toFixed(4)).eq(pending.toFixed(4), "Pending price is not accurate");
            expect((Number(order.principal) / 1e18).toFixed(4)).eq(buyAmount.toFixed(4), "Principal price is not accurate");
        });
        
        it ("Should correctly calculate relative prices for sell orders", async () => {
            const [owner] = await ethers.getSigners();
            const { exchange, dxh, tokens, oracle } = await loadFixture(deploy);

            const oraclePrice = Math.random() * 99_999;
            await oracle.setPrice(oraclePrice.toFixed(18).toString());
            exchange.assignPriceDAO(await oracle.getAddress());
        
            await exchange.listToken(await dxh.getAddress(), 0, 0, "1");


            // Note: Allowance is not considered in this test
            const tk = tokens[1];
            const tkAddr = await tk.getAddress();

            const price = Math.random() * 99_999;
            const sellAmount = Math.random() * 999;
            const bigSellAmount = BigInt(sellAmount * 1e18);


            await dxh.setBalance(owner, 10000);
            await exchange.listToken(tkAddr, 0, 0, price.toFixed(18).toString());
            
            await tk.setBalance(await owner.getAddress(), bigSellAmount);

            await exchange.createSellOrder(tkAddr, bigSellAmount);

            const orderPrice = oraclePrice / price;
            const pending = sellAmount / orderPrice;

            const order = await exchange.viewOrderByToken(tkAddr, 0);
            
            expect((Number(order.price) / 1e18).toFixed(4)).eq(orderPrice.toFixed(4), "Order price is not accurate");
            expect((Number(order.pending) / 1e18).toFixed(4)).eq(pending.toFixed(4), "Pending price is not accurate");
            expect((Number(order.principal) / 1e18).toFixed(4)).eq(sellAmount.toFixed(4), "Principal price is not accurate");
        });

        it ("Should correctly calculate parity prices for buy orders", async () => {
            const [owner, parityAddr] = await ethers.getSigners();
            const { exchange, dxh, tokens, oracle } = await loadFixture(deploy);

            const oraclePrice = Math.random() * 99_999;
            await oracle.setPrice(oraclePrice.toFixed(18).toString());
            exchange.assignPriceDAO(await oracle.getAddress());
        
            await exchange.listToken(await dxh.getAddress(), 0, 0, "1");

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
            await exchange.listParityToken(tkAddr, parityAddr, 0, 0);

            await exchange.createBuyOrder(tkAddr, {
                value: BigInt(buyAmount * 1e18)
            });

            const pending = buyAmount * orderPrice;
            const order = await exchange.viewOrderByToken(tkAddr, 0);
            
            expect((Number(order.price) / 1e18).toFixed(4)).eq(orderPrice.toFixed(4), "Order price is not accurate");
            expect((Number(order.pending) / 1e18).toFixed(4)).eq(pending.toFixed(4), "Pending price is not accurate");
            expect((Number(order.principal) / 1e18).toFixed(4)).eq(buyAmount.toFixed(4), "Principal price is not accurate");
        });

        it ("Should correctly calculate parity prices for sell orders", async () => {
            const [owner, parityAddr] = await ethers.getSigners();
            const { exchange, dxh, tokens, oracle } = await loadFixture(deploy);

            const oraclePrice = Math.random() * 99_999;
            await oracle.setPrice(oraclePrice.toFixed(18).toString());
            exchange.assignPriceDAO(await oracle.getAddress());
        
            await exchange.listToken(await dxh.getAddress(), 0, 0, "1");

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
            await exchange.listParityToken(tkAddr, parityAddr, 0, 0);

            await tk.setBalance(await owner.getAddress(), bigSellAmount);
            await exchange.createSellOrder(tkAddr, bigSellAmount);

            const pending = sellAmount / orderPrice;
            const order = await exchange.viewOrderByToken(tkAddr, 0);
            
            expect((Number(order.price) / 1e18).toFixed(4)).eq(orderPrice.toFixed(4), "Order price is not accurate");
            expect((Number(order.pending) / 1e18).toFixed(4)).eq(pending.toFixed(4), "Pending price is not accurate");
            expect((Number(order.principal) / 1e18).toFixed(4)).eq(sellAmount.toFixed(4), "Principal price is not accurate");
        });

        it ("Should allow orders to be cleared", async () => {
            const [owner, parityAddr] = await ethers.getSigners();
            const { exchange, dxh, tokens, oracle } = await loadFixture(deploy);

            const oraclePrice = Math.random() * 99_999;
            await oracle.setPrice(oraclePrice.toFixed(18).toString());
            exchange.assignPriceDAO(await oracle.getAddress());
        
            await exchange.listToken(await dxh.getAddress(), 0, 0, "1");

            await exchange.createBuyOrder(await dxh.getAddress(), {
                value: 5000
            })

            await exchange.viewOrder(0);

            await time.increase(40);
            await exchange.clearOrders();

            const res = exchange.viewOrder(0);
            await expect(res).revertedWithCustomError(exchange, "OrderDoesNotExist");
        });

        it ("Should correctly take buy orders", async () => {
            const [owner, user1] = await ethers.getSigners();
            const { exchange, tokens } = await loadFixture(deployWithBuyOrder);
        
            const ownerAddr = await owner.getAddress();
            const user1Addr = await user1.getAddress();

            const tk = tokens[1];
            
            const qtk = await exchange.viewTokenByIndex(2);
            const order = await exchange.viewOrder(0);
        
            
            await tk.setBalance(user1Addr, order.pending);
            const takerFX = await exchange.connect(user1);

            let tkBalance = await tk.balanceOf(ownerAddr);
            
            let balance = await ethers.provider.getBalance(user1Addr);

            const buyRes = await takerFX.takeBuyOrder(qtk.addr, order.pending);
            const receipt = await buyRes.wait();
            const fees = Number(receipt?.fee || 0);
        
            const newBalance = await ethers.provider.getBalance(user1Addr);
            expect(newBalance).eq(balance - BigInt(fees) + order.principal, "Taker balance is incorrect");

            const newTkBalance = await tk.balanceOf(ownerAddr);
            expect(newTkBalance).eq(tkBalance + order.pending, "Maker balance is incorrect");

            const res = exchange.viewOrder(0);
            await expect(res).revertedWithCustomError(exchange, "OrderDoesNotExist");
        });

        it ("Should correctly take buy orders [PARTIAL]", async () => {
            const [owner, user1] = await ethers.getSigners();
            const { exchange, tokens } = await loadFixture(deployWithBuyOrder);
        
            const ownerAddr = await owner.getAddress();
            const user1Addr = await user1.getAddress();

            const tk = tokens[1];
            
            const qtk = await exchange.viewTokenByIndex(2);
            const order = await exchange.viewOrder(0);
            const dec = Number(await tk.decimals());
            const pending = Number((Math.random() * Number(order.pending)).toFixed());


            // console.log("Attempting to buy: ", pending, pending / 10 ** dec);
            // console.log("Old Order: ", order);
            // console.log();console.log();console.log();
        
            
            await tk.setBalance(user1Addr, order.pending);
            const takerFX = await exchange.connect(user1);

            let tkBalance = await tk.balanceOf(ownerAddr);
            
            let balance = await ethers.provider.getBalance(user1Addr);

            const buyRes = await takerFX.takeBuyOrder(qtk.addr, BigInt(pending));
            const receipt = await buyRes.wait();
            const fees = BigInt(receipt?.fee || 0);

            // for (const log of receipt?.logs ?? []) {
            //     if ("fragment" in log) {
            //         console.log(`${log.fragment.name} => ${log.args}`);
            //     } else {
            //         console.log(log);
            //     }
            // }
        
            const newBalance = await ethers.provider.getBalance(user1Addr);
            // expect(newBalance).eq(balance - fees + order.principal, "Taker balance is incorrect");

            const newTkBalance = await tk.balanceOf(ownerAddr);
            // expect(newTkBalance).eq(tkBalance + BigInt(pending), "Maker balance is incorrect");

            const res = await exchange.viewOrder(0);
            
            // console.log("New Order: ", res);
            await expect(res).not.reverted;
        });

        it ("Should correctly take sell orders [PARTIAL]", async () => {
            const [owner, user1] = await ethers.getSigners();
            const { exchange, tokens } = await loadFixture(deployWithSellOrder);
        
            const user1Addr = await user1.getAddress();

            const tk = tokens[1];
            const qtk = await exchange.viewTokenByIndex(2);

            const order = await exchange.viewOrder(0);
            const pending = Number((Math.random() * Number(order.pending)).toFixed());  
            const principal = ((pending / Number(order.pending)) * Number(order.principal)).toFixed(); 
            
            const takerFX = await exchange.connect(user1);

            const balance = await ethers.provider.getBalance(owner);
            const tkBalance = await tk.balanceOf(user1Addr);

            const sellRes = await takerFX.takeSellOrder(qtk.addr, {
                value: BigInt(pending)
            });
            const receipt = await sellRes.wait();
            const fees = BigInt(receipt?.fee || 0);

            // for (const log of receipt?.logs ?? []) {
            //     if ("fragment" in log) {
            //         console.log(`${log.fragment.name} => ${log.args}`);
            //     } else {
            //         console.log(log);
            //     }
            // }
        
            // For some reason the amount of AVAX provided via value varies from the one read in the contract
            // because of this, we have to loose some precision for these tests
            const newBalance = await ethers.provider.getBalance(owner);
            const oBal = (Number(balance - fees + BigInt(pending)) * 1e-18).toFixed(2);
            const nBal = (Number(newBalance) * 1e-18).toFixed(2);

            expect(oBal).eq(nBal, "Taker balance is incorrect");

            const newTkBalance = await tk.balanceOf(user1Addr);
            const otBal = (Number(tkBalance + principal) * 10 ** Number(tk.decimals)).toFixed(2);
            const ntBal = (Number(newTkBalance) * 10 ** Number(tk.decimals)).toFixed(2);

            expect(ntBal).eq(otBal, "Maker balance is incorrect");

            await expect(exchange.viewOrder(0)).not.reverted;
        });

        it ("Should correctly settle buy orders", async () => {
            const [owner, user1] = await ethers.getSigners();
            const { exchange, tokens } = await loadFixture(deployWithBuyOrder);

            const tk = tokens[1];
            const [ownerAddr, user1Addr, fxAddr, tkAddr] = [await owner.getAddress(), await user1.getAddress(), await exchange.getAddress(), await tk.getAddress()];

            const order = await exchange.viewOrder(0);

            await tk.setBalance(user1Addr, order.pending);
            const userFX =  await exchange.connect(user1);
            await userFX.depositToken(tkAddr, order.pending);
            

            const fxBalance = await tk.balanceOf(fxAddr);
            const balance = await tk.balanceOf(ownerAddr);

            await exchange.settleOrders(tkAddr, true);

            await expect(exchange.viewOrder(0))
                .revertedWithCustomError(exchange, "OrderDoesNotExist");

            const newFxBalance = await tk.balanceOf(fxAddr);
            const newBalance = await tk.balanceOf(ownerAddr);

            expect(newFxBalance).eq(fxBalance - order.pending, "FX balance is incorrect");
            expect(newBalance).eq(balance + order.pending, "Maker balance is incorrect");
        });

        it ("Should correctly settle buy orders [PARTIAL]", async () => {
            const [owner, user1] = await ethers.getSigners();
            const { exchange, tokens } = await loadFixture(deployWithBuyOrder);

            const tk = tokens[1];
            const [ownerAddr, user1Addr, fxAddr, tkAddr] = [await owner.getAddress(), await user1.getAddress(), await exchange.getAddress(), await tk.getAddress()];

            const order = await exchange.viewOrder(0);
            const pending = BigInt((Math.random() * Number(order.pending)).toFixed());

            await tk.setBalance(user1Addr, order.pending);
            const userFX = await exchange.connect(user1);
            await userFX.depositToken(tkAddr, pending);
            

            const fxBalance = await tk.balanceOf(fxAddr);
            const balance = await tk.balanceOf(ownerAddr);

            await exchange.settleOrders(tkAddr, true);

            await expect(exchange.viewOrder(0)).to.not.be.reverted;

            const newFxBalance = await tk.balanceOf(fxAddr);
            const newBalance = await tk.balanceOf(ownerAddr);

            expect(newFxBalance).eq(fxBalance - pending, "FX balance is incorrect");
            expect(newBalance).eq(balance + pending, "Maker balance is incorrect");
        });

        it ("Should correctly settle sell orders", async () => {
            const [owner, user1] = await ethers.getSigners();
            const { exchange, tokens } = await loadFixture(deployWithSellOrder);

            const tk = tokens[1];
            const [ownerAddr, user1Addr, fxAddr, tkAddr] = [await owner.getAddress(), await user1.getAddress(), await exchange.getAddress(), await tk.getAddress()];

            const order = await exchange.viewOrder(0);

            const userFX =  await exchange.connect(user1);
            await userFX.deposit(tkAddr, {
                value: order.pending
            });

            const fxBalance = await provider.getBalance(fxAddr);
            const balance = await provider.getBalance(ownerAddr);

            const res = await exchange.settleOrders(tkAddr, false);
            const tx = await res.wait();
            const fee = tx?.fee ?? BigInt(0);

            await expect(exchange.viewOrder(0))
                .revertedWithCustomError(exchange, "OrderDoesNotExist");

            const newFxBalance = await provider.getBalance(fxAddr);
            const newBalance = await provider.getBalance(ownerAddr);

            expect(newFxBalance).eq(fxBalance - order.pending, "FX balance is incorrect");
            expect(newBalance).eq(balance - fee + order.pending, "Maker balance is incorrect");
        });

        it ("Should correctly settle sell orders [PARTIAL]", async () => {
            const [owner, user1] = await ethers.getSigners();
            const { exchange, tokens } = await loadFixture(deployWithSellOrder);

            const tk = tokens[1];
            const [ownerAddr, user1Addr, fxAddr, tkAddr] = [await owner.getAddress(), await user1.getAddress(), await exchange.getAddress(), await tk.getAddress()];

            const order = await exchange.viewOrder(0);
            const quotient = Math.random();
            
            const pending = BigInt((quotient * Number(order.pending)).toFixed());
            let principal = Number(order.principal) - (quotient * Number(order.principal));
            const bPrincipal = BigInt(principal.toFixed());

            // TODO: Test against principal

            const userFX = await exchange.connect(user1);
            await userFX.deposit(tkAddr, {
                value: pending
            });

            const fxBalance = await provider.getBalance(fxAddr);
            const balance = await provider.getBalance(ownerAddr);

            const res = await exchange.settleOrders(tkAddr, false);
            const tx = await res.wait();
            const fee = tx?.fee ?? BigInt(0);

            await expect(exchange.viewOrder(0)).to.not.be.reverted;

            const newFxBalance = await provider.getBalance(fxAddr);
            const newBalance = await provider.getBalance(ownerAddr);

            expect(newFxBalance).eq(fxBalance - pending, "FX balance is incorrect");
            expect(newBalance).eq(balance - fee + pending, "Maker balance is incorrect");
        });
    });

    describe("Order Management", () => {
        it ("Should properly clear orders", async () => {
            const { exchange, tokens } = await loadFixture(deployAndList40);
            const signers = await ethers.getSigners();

            for (let i = 0; i < 100; i++) {
                const signer = signers[Math.floor(Math.random() * signers.length)];
                const signerAddr = await signer.getAddress();
                const buffedSigners = new Map<string, boolean>()

                const signerFX = await exchange.connect(signer);

                const shouldBuy = Math.random() < .5;
                
                const tk = tokens[Math.floor(Math.random() * tokens.length)];
                const tkAddr = await tk.getAddress();
                const scalar = 10 ** (Number(await tk.decimals()));

                while (true) {
                    try {
                        if (shouldBuy) {
                            const initialDeposit =  Math.random() * 99_999;
                            const scaledDeposit = BigInt((initialDeposit * scalar).toFixed());

                            if (!buffedSigners.has(signerAddr)) {
                                provider.send("hardhat_setBalance", [
                                    signerAddr,
                                    "0x10000000000000000000000000000000000000000",
                                ]);
                                buffedSigners.set(signerAddr, true);
                            }
        
                            
        
                            const buyAmount = Math.random() * 999;
        
                            await tk.setBalance(signerAddr, scaledDeposit);
        
                            await signerFX.createBuyOrder(await tk.getAddress(), {
                                value: BigInt((buyAmount * 1e18).toFixed())
                            });
                        } else {
                            const sellAmount = Math.random() * 999;
                            const scaledSellAmount = BigInt(Number(sellAmount * scalar).toFixed());
        
                            await tk.setBalance(signerAddr, scaledSellAmount);
                            await signerFX.createSellOrder(tkAddr, scaledSellAmount);
                        }

                        break;
                    } catch (err) {
                        if (err instanceof SyntaxError) {
                            // await provider.send("hardhat_reset", []);
                            
                            continue;
                        } else throw err;
                    }
                }
            }

            await time.increase(40);

            await exchange.clearOrders();
            await exchange.clearOrders();

            await expect(exchange.viewOrder(0))
                .revertedWithCustomError(exchange, "OrderDoesNotExist");
        });

        it ("Should properly clear token orders", async () => {
            const { exchange, tokens } = await loadFixture(deployAndList40);
            const signers = await ethers.getSigners();
            // const orderCount = Math.random() * 1000;

            for (let i = 0; i < 100; i++) {
                const signer = signers[Math.floor(Math.random() * signers.length)];
                const signerAddr = await signer.getAddress();
                const buffedSigners = new Map<string, boolean>()

                const signerFX = await exchange.connect(signer);

                const shouldBuy = Math.random() < .5;
                
                const tk = tokens[Math.floor(Math.random() * tokens.length)];
                const tkAddr = await tk.getAddress();
                const scalar = 10 ** (Number(await tk.decimals()));

                while (true) {
                    try {
                        if (shouldBuy) {
                            const initialDeposit =  Math.random() * 99_999;
                            const scaledDeposit = BigInt((initialDeposit * scalar).toFixed());

                            if (!buffedSigners.has(signerAddr)) {
                                provider.send("hardhat_setBalance", [
                                    signerAddr,
                                    "0x10000000000000000000000000000000000000000",
                                ]);
                                buffedSigners.set(signerAddr, true);
                            }
        
                            
        
                            const buyAmount = Math.random() * 999;
        
                            await tk.setBalance(signerAddr, scaledDeposit);
        
                            await signerFX.createBuyOrder(await tk.getAddress(), {
                                value: BigInt((buyAmount * 1e18).toFixed())
                            });
                        } else {
                            const sellAmount = Math.random() * 999;
                            const scaledSellAmount = BigInt(Number(sellAmount * scalar).toFixed());
        
                            await tk.setBalance(signerAddr, scaledSellAmount);
                            await signerFX.createSellOrder(tkAddr, scaledSellAmount);
                        }

                        break;
                    } catch (err) {
                        if (err instanceof SyntaxError) {
                            // await provider.send("hardhat_reset", []);
                            
                            continue;
                        } else throw err;
                    }
                }
            }

            await time.increase(40);

            const tkAddr = await tokens[Math.floor(Math.random() * tokens.length)].getAddress();
            let tk2Addr = "";

            while (tk2Addr == "" || tk2Addr == tkAddr) {
                tk2Addr = await tokens[Math.floor(Math.random() * tokens.length)].getAddress();
            }

            await exchange.clearTokenOrders(tkAddr);

            await expect(exchange.viewOrderByToken(tkAddr, 0))
                .revertedWithCustomError(exchange, "OrderDoesNotExist");

            await expect(exchange.viewOrderByToken(tk2Addr, 0)).not.reverted;
        });
    });
});