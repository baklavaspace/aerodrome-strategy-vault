// npx hardhat run scripts/deploy.js --network base
// npx hardhat verify --constructor-args arguments.js --network baseGoerli 0xXXX
// npx hardhat verify --network base 0xXXX

// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.

const hre = require("hardhat");
const { ethers, upgrades } = require("hardhat");

function tokens(n) {
  return hre.ethers.parseEther(n);
}

async function main() {
  const max = "115792089237316195423570985008687907853269984665640564039457584007913129639935"

  /* ******** Mainnet(Base) ******** */
  const dummy = "0x0000000000000000000000000000000000000000"
  const weth = "0x4200000000000000000000000000000000000006"
  const usdc = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
  const well = "0xA88594D404727625A9437C3f886C7643872296AE"

  const mwUSDC = "0xc1256Ae5FF1cf2719D4937adb3bbCCab2E00A2Ca"
  const mwWETH = "0xa0E430870c4604CcfC7B38Ca7845B1FF653D0ff1"

  const owner = "0x4e3DA49cc22694D53F4a71e4d4BfdFB2BF272887"
  const governor = "0x3d726F33E25DEf0e1Abc9830Bea878B03ab6DB4D"

  const rewardDistributor = "0xe48C3eA37D4956580799d90a4601887d77A57d55"
  const treasury = "0x5c24B402b4b4550CF94227813f3547B94774c1CB"
  const aerorouter = "0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43"    // AeroSwapper






  /*********************************************************************
   ***************** Deploy MoonwellStrategyVault **********************
   *********************************************************************/

  const MoonwellStrategyVault = await ethers.getContractFactory("MoonwellFlagshipStrategyVault");
  // const aerodromeStrategyVault = await upgrades.upgradeProxy("0xF32D39ff9f6Aa7a7A64d7a4F00a54826Ef791a55", MoonwellStrategyVault, {kind: "uups", timeout: '0', pollingInterval: '1000'});
  const aerodromeStrategyVault = await upgrades.deployProxy(MoonwellStrategyVault, [usdc, governor, governor, "BRT2: moonwell USDC", "BRT2 mwUsdc"], {kind: "uups", timeout: '0', pollingInterval: '1000'});
  await aerodromeStrategyVault.waitForDeployment();
  
  console.log("Contract address:", await aerodromeStrategyVault.getAddress(), aerodromeStrategyVault.target);

  const outputToNativeRoute = [[well, weth, false, "0x420DD381b31aEf6683db6B902084cB0FFECe40Da"]]  // always same
  const outputToLpRoute = [[weth, usdc, false, "0x420DD381b31aEf6683db6B902084cB0FFECe40Da"]]

  await aerodromeStrategyVault.initVault(mwUSDC, well, aerorouter, treasury, rewardDistributor, outputToNativeRoute, outputToLpRoute);
  await aerodromeStrategyVault.updateFeeBips([tokens("0.0001"), "500", "100", "10"])
  await aerodromeStrategyVault.grantRole("0x4f574e45525f524f4c4500000000000000000000000000000000000000000000", owner);
  await aerodromeStrategyVault.grantRole("0x474f5645524e4f525f524f4c4500000000000000000000000000000000000000", owner);
  await aerodromeStrategyVault.approveAllowances(max)
  
  console.log("done")




}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});