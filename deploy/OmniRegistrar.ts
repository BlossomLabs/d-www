import assert from 'assert'

import { type DeployFunction } from 'hardhat-deploy/types'
import { EndpointId } from '@layerzerolabs/lz-definitions'
import { ethers } from 'hardhat'

const contractName = 'OmniRegistrar'

const deploy: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre

    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    assert(deployer, 'Missing named deployer account')

    console.log(`Network: ${hre.network.name}`)
    console.log(`Deployer: ${deployer}`)

    // This is an external deployment pulled in from @layerzerolabs/lz-evm-sdk-v2
    //
    // @layerzerolabs/toolbox-hardhat takes care of plugging in the external deployments
    // from @layerzerolabs packages based on the configuration in your hardhat config
    //
    // For this to work correctly, your network config must define an eid property
    // set to `EndpointId` as defined in @layerzerolabs/lz-definitions
    //
    // For example:
    //
    // networks: {
    //   fuji: {
    //     ...
    //     eid: EndpointId.AVALANCHE_V2_TESTNET
    //   }
    // }
    const omninameDeployment = await hre.deployments.get('OmniName')

    const args = [
        omninameDeployment.address,
        EndpointId.SCROLL_V2_MAINNET
    ]

    const { address } = await deploy(contractName, {
        from: deployer,
        args,
        log: true,
        skipIfAlreadyDeployed: false,
    })

    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${address}`)
    console.log(`To verify contract run: npx hardhat verify --network ${hre.network.name} ${address} ${args.join(' ')}`)

    // Retrieve deployed OmniName contract
    const omniName = await ethers.getContractAt('OmniName', omninameDeployment.address)

    // Change ownership of OmniName to the deployed contract
    console.log('Changing ownership of OmniName to OmniRegistrar...')
    const tx = await omniName.transferOwnership(address)
    await tx.wait();
    console.log('Ownership transferred successfully!')
}

deploy.tags = [contractName]
deploy.dependencies = ['OmniName']

export default deploy
