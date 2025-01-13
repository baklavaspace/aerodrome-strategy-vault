// npx hardhat run scripts/deploy.js --network localTest
// npx hardhat verify --constructor-args arguments.js --network baseGoerli 0x38D0eE682AD007426A929A7ef71f7527eFf61dF8
// npx hardhat verify --network optimisticEthereum 0x2d25Da8aD2c42d56E521F634848101cA066dD2BB

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
  const weth = "0x4200000000000000000000000000000000000006"
  // const aero = "0x940181a94A35A4569E4529A3CDfB74e38FD98631"
  // // const usdbc = "0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA"
  // const usdc = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
  // const dola = "0x4621b7A9c75199271F773Ebd9A499dbd165c3191"
  // // const wstEth = "0xc1CBa3fCea344f92D9239c08C0568f6F2F0ee452"
  // // const bava = "0x3fbdE9864362CE4Abb244EbeF2EF0482ABA8eA39"
  // const klima = "0xDCEFd8C8fCc492630B943ABcaB3429F12Ea9Fea2"
  // const wels = "0x7F62ac1e974D65Fab4A81821CA6AF659A5F46298"
  // const hbr = "0x416bd43Bc76D496ff49923c20eCaf86b52Ab078d"
  // const spot = "0x8f2E6758C4D6570344bd5007DEc6301cd57590A0"
  // const l2ve = "0xA19328fb05ce6FD204D16c2a2A98F7CF434c12F4"
  // const well = "0xA88594D404727625A9437C3f886C7643872296AE"
  // const dummyReward = "0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA"

  // const bavaBase = "0x3fbdE9864362CE4Abb244EbeF2EF0482ABA8eA39"
  // const bavaBSC = "0x3fbdE9864362CE4Abb244EbeF2EF0482ABA8eA39"
  // const bavaFxCore = ""
  // const bavaAvalanche = ""
  // const esBAVA = "0x77E74e7E92ecB9E921e7447c3FC35547E1C61f99"

  const dummy = "0x0000000000000000000000000000000000000000"

  // const lp_Weth_USDbc = "0xB4885Bc63399BF5518b994c1d0C153334Ee579D0"
  // const lp_Weth_wstETH = "0xA6385c73961dd9C58db2EF0c4EB98cE4B60651e8"
  // const lp_Weth_Aero = ""
  // const lp_Aero_USDbc = "0x2223F9FE624F69Da4D8256A7bCc9104FBA7F8f75"
  // const lp_Aero_USDC = "0x6cDcb1C4A4D1C3C6d054b27AC5B77e89eAFb971d"
  // const lp_Aero_BAVA = "0xD3c2fa602B8da5b0b9c25dFBE7F2f31Bb512dB13"

  // const lp_Usdc_Klima = "0x958682eC6282BC7E939FA8Ba9397805C214c3A09"
  // const lp_Weth_Klima = "0xB37642E87613d8569Fd8Ec80888eA6c63684E79e"
  // const lp_Weth_Wels = "0xCaedc2561356B6a01a94E3C0438011459E91FBb9"
  // const lp_Hbr_Usdc = "0x68cfB52C74827f91E1F664fFeD634F849AEce455"
  // const lp_Usdc_Spot = "0xa43455d99Eb63473cFA186b388c1BC2EA1B63924"
  // const lp_Dola_Usdc = "0xf213F2D02837012dC0236cC105061e121bB03e37"
  // const lp_Aero_L2ve = "0xFC13b664e814098F08F10bA0fb23b1Bb916F344e"
  // const lp_Weth_Well = "0x89D0F320ac73dd7d9513FFC5bc58D1161452a657"

  // const gauge_Weth_USDbc = "0xeca7Ff920E7162334634c721133F3183B83B0323"
  // const gauge_Weth_wstETH = "0xDf7c8F17Ab7D47702A4a4b6D951d2A4c90F99bf4"
  // const gauge_Weth_Aero = ""
  // const gauge_Aero_USDbc = "0x9a202c932453fB3d04003979B121E80e5A14eE7b"
  // const gauge_Aero_USDC = "0x4F09bAb2f0E15e2A078A227FE1537665F55b8360"
  // const gauge_Aero_BAVA = "0xE3Da183CDBbd0F01867605C632F1E275e7eD6E3D"

  // const gauge_Usdc_Klima = "0x950aD950D6f07491ef2c150545A6A2AB7AdC03f4"
  // const gauge_Weth_Klima = "0x44A927DD8f6def04f76B00cece9804BF441dc6b1"
  // const gauge_Weth_Wels = "0xdE41799DE5fB357f501dd9386ACee424E816f7a6"
  // const gauge_Hbr_Usdc = "0xce0358DFf7Bcf904f21425f6fee7F8E6115372cd"
  // const gauge_Usdc_Spot = "0xD90C0E9728fe44905384C89d867Ba095e2Dc3E2e"
  // const gauge_Dola_Usdc = "0xCCff5627cd544b4cBb7d048139C1A6b6Bde67885"
  // const gauge_Aero_L2ve = "0x9B49ca7C6C41f01971e2453078a357415Cb3Adda"
  // const gauge_Weth_Well = "0x7b6964440b615aC1d31bc95681B133E112fB2684"

  // const router = "0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43"
  // const poolFactory = "0x420DD381b31aEf6683db6B902084cB0FFECe40Da"
  const owner = "0x4e3DA49cc22694D53F4a71e4d4BfdFB2BF272887"
  const governor = "0x3d726F33E25DEf0e1Abc9830Bea878B03ab6DB4D"

  // const rewardDistributor = "0xe48C3eA37D4956580799d90a4601887d77A57d55"
  // const treasury = "0x5c24B402b4b4550CF94227813f3547B94774c1CB"
  // const multiCal = ""


  /* ******** Mainnet(Optimism) ******** */
  const lp_Usdc_Velo = "0xa0A215dE234276CAc1b844fD58901351a50fec8A"
  const gauge_Velo_Usdc = "0xFf6b058484517BF58450DfC4a6eb53F1A2171775"

  const rewardDistributor = "0x83B2D994A1d16E6A3A44281D12542E2bc0d5EBFD"
  const velo = "0x9560e827aF36c94D2Ac33a39bCE1Fe78631088Db"
  const router = "0xa062aE8A9c5e11aaA026fc2670B0D65cCc8B2858"
  const poolFactory = "0xF1046053aa5682b4F9a81b5481394DA16BE5FF5a"
  const treasury = "0x37f716f6693EB2681879642e38BbD9e922A53CDf"

  const usdc = "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85"

  // const lp_Weth_USDbc_vault = ""
  // const lp_Weth_Aero_vault = ""
  // const lp_USDbc_Aero_vault = ""




  const [xx] = await ethers.getSigners();
  console.log(xx.address)
  // const balance0ETH = await ethers.provider.getBalance("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");   // hardhat test account
  const balance0ETH = await ethers.provider.getBalance("0x3d726F33E25DEf0e1Abc9830Bea878B03ab6DB4D");
  console.log(balance0ETH)
  /****Send ether * */ 
  // for(i=0;i<5000;i++) {
  //   await xx.sendTransaction({
  //     to: '0xfe6e9353000a31B9C87F4EAE411C89b1E355Ba50',
  //     value: '10',
  //   });
  // }
  // const balance1ETH = await ethers.provider.getBalance("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");
  // console.log(balance1ETH)
  // console.log("......")

  // const latestBlock = await hre.ethers.provider.getBlockNumber()

  /* ******** Testnet(base sepolia) ******** */
  // const weth = "0x4200000000000000000000000000000000000006"  
  // const aero = "0xa8f29635C9A6DaE9BFBC36F1d1f492CB964bc5e6"
  // const usdbc = "0xEAe3d65c605b4Bc50fF44Db08EA6e16b06C75Ce0"
  // const dummyReward = "0xfF5D5d8949c67dB0Ce0433068eA45a5be242B9eb"

  // const lp_Weth_USDbc = "0x4E22F28aD4c615B51f07e4946bAcBbfacCA07214"
  // const lp_Weth_Aero = "0x71f062398cDeDFBf12C244f10fA5aE34caF21bF1"
  // const lp_USDbc_Aero = "0x1569E8B813C038b5A33DBE2DC2bF4554a1fdcDE2"

  // const gauge_Weth_USDbc = "0xECDb20b971cb9163A5216B7B2b974BB6DA4bbc0a"
  // const gauge_Weth_Aero = "0x8E5D5A4701d53799cECf1aE67f393c0ce4540A87"
  // const gauge_USDbc_Aero = "0x42Fb25640E9F2Ee166bA8715aa3E18455b353801"

  // const router = "0xC9D46a82CDC9Af7893F5831C1a74cF0b1a85b218"

  // const owner = "0xfe6e9353000a31B9C87F4EAE411C89b1E355Ba50"
  // const governor = "0xfe6e9353000a31B9C87F4EAE411C89b1E355Ba50"

  // const rewardDistributor = "0x26aDb26B70f8ecE42789291548AB144a00B0dD2C"   // Base Goerli
  // const multiCal = ""

  // const lp_Weth_USDbc_vault = "0xFd27475EE1355F6Af8055a9C286d5A1B38393a38"
  // const lp_Weth_Aero_vault = "0x1DD3c31e43DE1bb20E4BCF5c01CF1bf030C18F02"
  // const lp_USDbc_Aero_vault = ""

  // const bavaSepoliaBase = "0xB83042Bf7d73695CA99516551DB7B15f24864398"
  // const esBAVASepoliaBase = "0xbE176B8908577177064D8D2083386779eE361754"
  // const veBAVASepoliaBase = "0x728a7327e3Dd0caFca7d3E85079865cf1537a773"
  // const rewardDistributorSepoliaBase = "0x8b5a52FF0a929D659762D58d169060c1404dA22E"


  /*****************************************************
   ***************** Deploy EsBAVA *********************
   *****************************************************/

  // const DummyToken = await ethers.getContractFactory("DummyToken");
  // const dummyToken = await upgrades.deployProxy(DummyToken, [owner, dummy, dummy, dummy], {kind: "uups", timeout: '0', pollingInterval: '1000'});
  
  // await dummyToken.waitForDeployment();
  // console.log("Contract address:", await dummyToken.getAddress());
  // console.log("Contract address:", await dummyToken.target);

  // const EsBAVA = await ethers.getContractFactory("EsBAVA");
  // const esBAVA = await upgrades.deployProxy(EsBAVA, [owner, dummy, dummy, dummy], {kind: "uups", timeout: '0', pollingInterval: '1000'});
  
  // await esBAVA.waitForDeployment();
  // console.log("Contract address:", await esBAVA.getAddress(), esBAVA.target);

  /*****************************************************
   ***************** Deploy Vester *********************
   *****************************************************/
   const bavaOp   = "0x3fbdE9864362CE4Abb244EbeF2EF0482ABA8eA39"
   const esBavaOp = "0x5c24B402b4b4550CF94227813f3547B94774c1CB"

  // //  const bavaAvax   = "0xe19A1684873faB5Fb694CfD06607100A632fF21c"
  // //  const esBAVAAvax = "0x5c24B402b4b4550CF94227813f3547B94774c1CB"

  // //   const bavaFuji   = "0x406c63341FAc265EAB505D7181A7cE8331Ff9c88"
  // //   const esBAVAFuji = "0xB4D03F459aD9b14d0Ad6B008190D7668dE2253D3"

  // // const bavaHardhat = "0x821f3361D454cc98b7555221A06Be563a7E2E0A6"
  // // const esBavaHardhat = "0x5133BBdfCCa3Eb4F739D599ee4eC45cBCD0E16c5"

  // // const Vester = await hre.ethers.getContractFactory("Vester");
  // // const deployment = await upgrades.forceImport('', Vester);
  // // console.log("Proxy imported from:", deployment.getAddress());

  // const Vester = await ethers.getContractFactory("Vester");
  // // const vester = await upgrades.upgradeProxy("0xe48C3eA37D4956580799d90a4601887d77A57d55", Vester, {kind: "uups", timeout: '0', pollingInterval: '1000'});
  // const vester = await upgrades.deployProxy(Vester, ["Vested BAVA", "veBAVA", "94608000", esBavaOp, bavaOp, owner, owner], {kind: "uups", timeout: '0', pollingInterval: '1000'});

  // await vester.waitForDeployment();
  // console.log("Contract address:", await vester.getAddress(), vester.target);

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
  // const rewardDistributor = await upgrades.deployProxy(RewardDistributor, [esBavaOp, owner, owner], {kind: "uups", timeout: '0', pollingInterval: '1000'});
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

  // const AerodromeStrategyVault = await ethers.getContractFactory("AerodromeStrategyVault");
  // // // const aerodromeStrategyVault = await upgrades.upgradeProxy("0xF32D39ff9f6Aa7a7A64d7a4F00a54826Ef791a55", AerodromeStrategyVault, {kind: "uups", timeout: '0', pollingInterval: '1000'});
  // const aerodromeStrategyVault = await upgrades.deployProxy(AerodromeStrategyVault, [lp_Usdc_Velo, governor, governor, "BRT2: vAMM USDC_VELO", "BRT2 vAMM"], {kind: "uups", timeout: '0', pollingInterval: '1000'});
  // await aerodromeStrategyVault.waitForDeployment();
  
  // console.log("Contract address:", await aerodromeStrategyVault.getAddress(), aerodromeStrategyVault.target);

  // const aerodromeStrategyVault = await hre.ethers.getContractAt("AerodromeStrategyVault", "0xF5E657e315d8766e0841eE83DeEE05aa836Cc8ce");

  // const outputToNativeRoute = [[velo, weth, false, poolFactory]]  // always same
  // const outputToLp0Route = [[weth, usdc, false, poolFactory]]
  // const outputToLp1Route = [[weth, velo, false, poolFactory]]

  // await aerodromeStrategyVault.initVault(gauge_Velo_Usdc, velo, router, treasury, rewardDistributor, outputToNativeRoute, outputToLp0Route, outputToLp1Route);
  // await aerodromeStrategyVault.updateFeeBips([tokens("0.0001"), "500", "100", "10"])
  // await aerodromeStrategyVault.grantRole("0x4f574e45525f524f4c4500000000000000000000000000000000000000000000", owner);
  // await aerodromeStrategyVault.grantRole("0x474f5645524e4f525f524f4c4500000000000000000000000000000000000000", owner);
  // await aerodromeStrategyVault.approveAllowances(max)
  
  // console.log("done")


  /*********************************************************************
   ***************** Deploy BavaStakingVault ***************************
   *********************************************************************/

  // const BavaStakingVault = await ethers.getContractFactory("BavaStakingVault");
  // // const aerodromeStrategyVault = await upgrades.upgradeProxy("0xc5DFb9698440Eaeb0A7C9dAA5a795e9B48CacadF", AerodromeStrategyVault, {kind: "uups", timeout: '0', pollingInterval: '1000'});
  // const bavaStakingVault = await upgrades.deployProxy(BavaStakingVault, [bavaOp, owner, owner, "BRT2: BAVA STAKING", "BRT2 BAVA"], {kind: "uups", timeout: '0', pollingInterval: '1000'});
  // await bavaStakingVault.waitForDeployment();
  
  // console.log("Contract address:", await bavaStakingVault.getAddress(), bavaStakingVault.target);

  // await bavaStakingVault.initVault(rewardDistributor);
  // await aerodromeStrategyVault.updateFeeBips([tokens("0.001"), "500", "100", "10"])
  // await aerodromeStrategyVault.grantRole("0x4f574e45525f524f4c4500000000000000000000000000000000000000000000", owner);
  // await aerodromeStrategyVault.grantRole("0x474f5645524e4f525f524f4c4500000000000000000000000000000000000000", owner);
  
  // console.log("done")









  /*****************************************************
   ***************** Test Deposit **********************
   *****************************************************/
  
  // const lp = await hre.ethers.getContractAt("AerodromeStrategyVault", "0xc5DFb9698440Eaeb0A7C9dAA5a795e9B48CacadF");
  // // await lp.grantRole("0x474f5645524e4f525f524f4c4500000000000000000000000000000000000000", "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");
  // let reward = await lp.checkReward()
  // console.log(reward)
  // await lp.compound()
  // const aeroToken = await hre.ethers.getContractAt("AerodromeStrategyVault", "0x940181a94A35A4569E4529A3CDfB74e38FD98631");
  // const aeroBalance = await aeroToken.balanceOf(lp.target)
  // console.log(aeroBalance)
  // await lp._convertWETHToDepositToken("")
  // console.log("done")
  // const wethToken = await hre.ethers.getContractAt("AerodromeStrategyVault", weth);
  // const wethBalance = await wethToken.balanceOf(lp.target)
  // console.log(wethBalance)

  // const depositToken = await hre.ethers.getContractAt("AerodromeStrategyVault", lp_Aero_USDC);
  // const depositBalance = await depositToken.balanceOf(lp.target)
  // console.log(depositBalance)
  
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