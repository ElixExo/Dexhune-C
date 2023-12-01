import { ethers } from "hardhat";

async function main() {
  const exchange = await ethers.deployContract("contracts/DexhuneExchange_flattened.sol:DexhuneExchange");
  console.log(
    `Exchange has been deployed to ${exchange.target}`
  );
  await exchange.waitForDeployment();
  
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
