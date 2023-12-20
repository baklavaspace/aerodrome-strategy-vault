// npx hardhat run scripts/deploy.js --network baseGoerli
// npx hardhat verify --constructor-args arguments.js --network baseGoerli 0x38D0eE682AD007426A929A7ef71f7527eFf61dF8
// npx hardhat verify --network base 0x49AF8CAf88CFc8394FcF08Cf997f69Cee2105f2b

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

  /* ******** Mainnet(FxCore) ******** */
  const weth = "0x4200000000000000000000000000000000000006"  
  const aero = "0x940181a94A35A4569E4529A3CDfB74e38FD98631"
  const usdbc = "0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA"
  const wstEth = "0xc1CBa3fCea344f92D9239c08C0568f6F2F0ee452"
  const dummyReward = "0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA"

  const lp_Weth_USDbc = "0xB4885Bc63399BF5518b994c1d0C153334Ee579D0"
  const lp_Weth_wstETH = "0xA6385c73961dd9C58db2EF0c4EB98cE4B60651e8"
  const lp_Weth_Aero = ""
  const lp_Aero_USDbc = "0x2223F9FE624F69Da4D8256A7bCc9104FBA7F8f75"

  const gauge_Weth_USDbc = "0xeca7Ff920E7162334634c721133F3183B83B0323"
  const gauge_Weth_wstETH = "0xDf7c8F17Ab7D47702A4a4b6D951d2A4c90F99bf4"
  const gauge_Weth_Aero = ""
  const gauge_Aero_USDbc = "0x9a202c932453fB3d04003979B121E80e5A14eE7b"

  const router = "0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43"

  const owner = "0x4e3DA49cc22694D53F4a71e4d4BfdFB2BF272887"
  const governor = "0x4e3DA49cc22694D53F4a71e4d4BfdFB2BF272887"

  const rewardDistributor = "0xe48C3eA37D4956580799d90a4601887d77A57d55"
  const treasury = "0x5c24B402b4b4550CF94227813f3547B94774c1CB"
  const multiCal = ""

  const lp_Weth_USDbc_vault = ""
  const lp_Weth_Aero_vault = ""
  const lp_USDbc_Aero_vault = ""

  // const latestBlock = await hre.ethers.provider.getBlockNumber()




  /*****************************************************
   ***************** Deploy FeeTreasury ****************
   *****************************************************/

  // const FeeTreasury = await ethers.getContractFactory("FeeTreasury");
  // const feeTreasury = await upgrades.deployProxy(FeeTreasury, [owner], {kind: "uups", timeout: '0', pollingInterval: '1000'});
  
  // await feeTreasury.waitForDeployment();
  // console.log("Contract address:", await feeTreasury.getAddress(), feeTreasury.target);

  // const feeTreasury = await hre.ethers.getContractAt("FeeTreasury", feeTreas);


  /*****************************************************
   ***************** Deploy RewardDistributor **********
   *****************************************************/

  // const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
  // // const rewardDistributor = await upgrades.upgradeProxy(rewardDis, RewardDistributor, {kind: "uups", timeout: '0', pollingInterval: '1000'});
  // const rewardDistributor = await upgrades.deployProxy(RewardDistributor, [usdbc, owner, governor], {kind: "uups", timeout: '0', pollingInterval: '1000'});
  // await rewardDistributor.waitForDeployment();
  
  // console.log("Contract address:", await rewardDistributor.getAddress());

  // const rewardDistributor = await hre.ethers.getContractAt("RewardDistributor", rewardDis);

  // await rewardDistributor.updateStartDistributionTime();
  // await rewardDistributor.add("0", FXSwapStrategyVault_lp_WFX_BAVA, true)
  // console.log("done")

  // await rewardDistributor.setTokensPerInterval("1000000000000")
  // await rewardDistributor.setTokensPerInterval("0")

  

  

  /*********************************************************************
   ***************** Deploy AerodromeStrategyVault ***************
   *********************************************************************/

  const AerodromeStrategyVault = await ethers.getContractFactory("AerodromeStrategyVault");
  const aerodromeStrategyVault = await upgrades.upgradeProxy("0x49AF8CAf88CFc8394FcF08Cf997f69Cee2105f2b", AerodromeStrategyVault, {kind: "uups", timeout: '0', pollingInterval: '1000'});
  // const aerodromeStrategyVault = await upgrades.deployProxy(AerodromeStrategyVault, [lp_Aero_USDbc, "0x3d726F33E25DEf0e1Abc9830Bea878B03ab6DB4D", "0x3d726F33E25DEf0e1Abc9830Bea878B03ab6DB4D", "BRT2: vAMM AERO-USDbc", "BRT2 vAMM"], {kind: "uups", timeout: '0', pollingInterval: '1000'});
  await aerodromeStrategyVault.waitForDeployment();
  
  console.log("Contract address:", await aerodromeStrategyVault.getAddress(), aerodromeStrategyVault.target);

  // const outputToNativeRoute = [[aero, weth, false, "0x420DD381b31aEf6683db6B902084cB0FFECe40Da"]]
  // const outputToLp0Route = [[weth, aero, false, "0x420DD381b31aEf6683db6B902084cB0FFECe40Da"]]
  // const outputToLp1Route = [[weth, usdbc, false, "0x420DD381b31aEf6683db6B902084cB0FFECe40Da"]]

  // await aerodromeStrategyVault.initVault(gauge_Aero_USDbc, aero, [], router, treasury, rewardDistributor, outputToNativeRoute, outputToLp0Route, outputToLp1Route);
  // await aerodromeStrategyVault.updateFeeBips([tokens("0.001"), "500", "100", "50"])
  // await aerodromeStrategyVault.grantRole("0x4f574e45525f524f4c4500000000000000000000000000000000000000000000", owner);
  // await aerodromeStrategyVault.grantRole("0x474f5645524e4f525f524f4c4500000000000000000000000000000000000000", owner);
  // await aerodromeStrategyVault.approveAllowances(max)
  
  console.log("done")




  /*****************************************************
   ***************** Test Deposit **********************
   *****************************************************/

  // const lp = await hre.ethers.getContractAt("FXSwapStrategyVault", lp_WFX_Bonus);
  // await lp.approve(fxSwapStrategyVault.target,  max)
  // console.log("done Approve")

  // let b4Asset = await fxSwapStrategyVault.totalAssets()
  // let b4Supply = await fxSwapStrategyVault.totalSupply()
  // // let b4Supply = await fxSwapStrategyVault.bavaBonusReward()
  // let reward = await fxSwapStrategyVault.checkReward()
  // let preview = await fxSwapStrategyVault.previewDeposit("42000000")
  // console.log("Asset = ", b4Asset, b4Supply, reward, preview)

  // await fxSwapStrategyVault.claimReward(governor)
  // // await fxSwapStrategyVault.updateRewards()

  // let b4Balance = await fxSwapStrategyVault.balanceOf(governor)
  // console.log(b4Balance)

  // await fxSwapStrategyVault.deposit("15485848881047651242", governor)
  // console.log("done deposit")

  // let afBalance = await fxSwapStrategyVault.balanceOf(governor)
  // console.log(afBalance)

  /* Test Redeem */
  // let afterDepositAsset = await fxSwapStrategyVault.totalAssets()
  // console.log("done Deposit", afterDepositAsset)

  // await fxSwapStrategyVault.compound()
  // let previewAsset = await fxSwapStrategyVault.previewRedeem("420000")
  // console.log("Asset = ", previewAsset)

  // await fxSwapStrategyVault.redeem("154858488810476512", governor, governor)

  // let afterWithdrawAsset = await fxSwapStrategyVault.totalAssets()
  // console.log("done withdraw", afterWithdrawAsset)

  // let afBalance = await fxSwapStrategyVault.balanceOf(governor)
  // console.log(afBalance)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});





