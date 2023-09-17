import { ethers } from "hardhat";

async function main() {
  const priceDao = await ethers.deployContract("DexhunePriceDAO");
  await priceDao.waitForDeployment();

  console.log(
    `Price DAO deployed to ${priceDao.target}`
  );
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
