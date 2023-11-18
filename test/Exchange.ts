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

import { loadFixture, mine, mineUpTo, time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { MockNFT, MockERC20 } from "../typechain-types";
import { DexhuneExchange } from "../typechain-types/DexhuneExchange.sol";

interface Context {
    exchange: DexhuneExchange,
    mockNFT: MockNFT,
    dxh: MockERC20,
    tokens: MockERC20[]
}

describe("Exchange", () => {
    async function deploy(): Promise<Context> {
        const ERC20Factory = await ethers.getContractFactory("MockERC20");
        
        const exchange = await (await ethers.getContractFactory("DexhuneExchange")).deploy();
        const mockNFT = await (await ethers.getContractFactory("MockNFT")).deploy()
        const dxh = await ERC20Factory.deploy();        

        return { exchange, mockNFT, dxh, tokens: [dxh] }
    }

    async function deployToken100(): Promise<Context> {
        const ERC20Factory = await ethers.getContractFactory("MockERC20");
        
        const exchange = await (await ethers.getContractFactory("DexhuneExchange")).deploy();
        const mockNFT = await (await ethers.getContractFactory("MockNFT")).deploy()
        const dxh = await ERC20Factory.deploy();

        const tokens: MockERC20[] = [dxh];
        for (let i = 0; i < 100; i++) {
            const tk = await ERC20Factory.deploy();
            tokens.push(tk);
        }

        return { exchange, mockNFT, dxh, tokens }
    }

    describe("Deployment", async () => {
        it ("Should have an incremental listing price", async () => {
            const { exchange, tokens } = await loadFixture(deployToken100);
            
            
            for (let i = 0; i < tokens.length; i++) {
                const tk = tokens[i];
                // tk.setBalance()


                const addr = await tk.getAddress();
                
                await exchange.listToken(addr, 1, 0, 0, "", "1");
            }
        });

        
    })
});