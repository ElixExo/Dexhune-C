import { ethers } from "hardhat";
import { config as dotEnvConfig } from "dotenv"

dotEnvConfig();

const OWNER = process.env.DEXHUNE_OWNER as string;
const WAIT_BLOCK_CONFIRMATIONS = 6;



async function main() {
  const priceDao = await ethers.deployContract("DexhunePriceDAO");
  
  console.log(
    `Price DAO deployed to ${priceDao.target}`
  );

  await priceDao.deploymentTransaction()?.wait(WAIT_BLOCK_CONFIRMATIONS);
  await priceDao.transferOwnership(OWNER)

  console.log(`Ownership transferred to ${OWNER}`);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
