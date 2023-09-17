import { ethers } from "hardhat";

async function main() {
  try {
    const dexhuneToken = await ethers.deployContract("DexhuneERC20");

    console.log(
      `DexhuneERC20 deployed to ${dexhuneToken.target}`
    );

    await dexhuneToken.waitForDeployment();
  } catch (err) {
    console.error(err);
    throw err;
  }
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
