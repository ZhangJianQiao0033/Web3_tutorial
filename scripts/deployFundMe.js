const { ethers } = require("hardhat")

async function main() {
    const fundMeFactory = await ethers.getContractFactory("FundMe");
    console.log("contract deploying")
    const fundMe = await fundMeFactory.deploy(10);
    await fundMe.waitForDeployment();
    console.log("contract has been deployed successfully ! contract address is " + fundMe.target)
    
    if(hre.network.config.chainId == 11155111 && process.env.ETHERSCAN_API_KEY){
        console.log("waitting for 5 confirmations ")
        await fundMe.deploymentTransaction().wait(5)
        await verifyFundMe(fundMe.target,[10])
    }else {

        console.log("verification skipped...")
    }
   
}

async function verifyFundMe (fundAddress, args) {
    await hre.run("verify:verify", {
        address: fundAddress,
        constructorArguments: args,
      })
}


main().then().catch((error) => {
    console.error(error)
    process.exit(1)
})