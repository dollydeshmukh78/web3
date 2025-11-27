const { ethers } = require("hardhat");

async function main() {
  const MetaFundTreasury = await ethers.getContractFactory("MetaFundTreasury");
  const metaFundTreasury = await MetaFundTreasury.deploy();

  await metaFundTreasury.deployed();

  console.log("MetaFundTreasury contract deployed to:", metaFundTreasury.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
