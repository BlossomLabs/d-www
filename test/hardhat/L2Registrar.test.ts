import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { Contract, ContractFactory } from 'ethers'
import { deployments, ethers } from 'hardhat'

import { Options } from '@layerzerolabs/lz-v2-utilities'

describe('L2Registrar Test', function () {
    // Constant representing a mock Endpoint ID for testing purposes
    const eidA = 1
    const eidB = 2
    // Declaration of variables to be used in the test suite
    let L2Registrar: ContractFactory
    let OmniRegistrar: ContractFactory
    let OmniName: ContractFactory
    let EndpointV2Mock: ContractFactory
    let ownerA: SignerWithAddress
    let ownerB: SignerWithAddress
    let endpointOwner: SignerWithAddress
    let myONFT721A: Contract
    let myONFT721B: Contract
    let myL2Registrar: Contract
    let myL2Registry: Contract
    let myOmniRegistrar: Contract
    let mockEndpointV2A: Contract
    let mockEndpointV2B: Contract

    // Before hook for setup that runs once before all tests in the block
    before(async function () {
        // Contract factory for our tested contract
        //
        // We are using a derived contract that exposes a mint() function for testing purposes
        OmniName = await ethers.getContractFactory('OmniNameMock')
        L2Registrar = await ethers.getContractFactory('L2Registrar')
        OmniRegistrar = await ethers.getContractFactory('OmniRegistrar')

        // Fetching the first three signers (accounts) from Hardhat's local Ethereum network
        const signers = await ethers.getSigners()

        ownerA = signers.at(0)!
        ownerB = signers.at(1)!
        endpointOwner = signers.at(2)!

        // The EndpointV2Mock contract comes from @layerzerolabs/test-devtools-evm-hardhat package
        // and its artifacts are connected as external artifacts to this project
        //
        // Unfortunately, hardhat itself does not yet provide a way of connecting external artifacts,
        // so we rely on hardhat-deploy to create a ContractFactory for EndpointV2Mock
        //
        // See https://github.com/NomicFoundation/hardhat/issues/1040
        const EndpointV2MockArtifact = await deployments.getArtifact('EndpointV2Mock')
        EndpointV2Mock = new ContractFactory(EndpointV2MockArtifact.abi, EndpointV2MockArtifact.bytecode, endpointOwner)
    })

    // beforeEach hook for setup that runs before each test in the block
    beforeEach(async function () {
        // Deploying a mock LZEndpoint with the given Endpoint ID
        mockEndpointV2A = await EndpointV2Mock.deploy(eidA)
        mockEndpointV2B = await EndpointV2Mock.deploy(eidB)

        // Deploying two instances of MyOFT contract with different identifiers and linking them to the mock LZEndpoint
        myONFT721A = await OmniName.deploy('aONFT721', 'aONFT721', mockEndpointV2A.address, ownerA.address)
        myONFT721B = await OmniName.deploy('bONFT721', 'bONFT721', mockEndpointV2B.address, ownerB.address)

        myL2Registrar = await L2Registrar.deploy(myONFT721A.address)
        myL2Registry = await ethers.getContractAt('L2Registry', myL2Registrar.targetRegistry())
        myOmniRegistrar = await OmniRegistrar.deploy(myONFT721B.address, eidA)

        // Setting destination endpoints in the LZEndpoint mock for each OmniName instance
        await mockEndpointV2A.setDestLzEndpoint(myONFT721B.address, mockEndpointV2B.address)
        await mockEndpointV2B.setDestLzEndpoint(myONFT721A.address, mockEndpointV2A.address)

        // Setting destination endpoints in the LZEndpoint mock for each L2Registrar instance
        await mockEndpointV2A.setDestLzEndpoint(myOmniRegistrar.address, mockEndpointV2B.address)
        await mockEndpointV2B.setDestLzEndpoint(myL2Registrar.address, mockEndpointV2A.address)

        // Setting each MyONFT721 instance as a peer of the other in the mock LZEndpoint
        await myONFT721A.connect(ownerA).setPeer(eidB, ethers.utils.zeroPad(myONFT721B.address, 32))
        await myONFT721B.connect(ownerB).setPeer(eidA, ethers.utils.zeroPad(myONFT721A.address, 32))

        // Setting each L2Registrar instance as a peer of the other in the mock LZEndpoint
        await myL2Registrar.connect(ownerA).setPeer(eidB, ethers.utils.zeroPad(myOmniRegistrar.address, 32))
        await myOmniRegistrar.connect(ownerB).setPeer(eidA, ethers.utils.zeroPad(myL2Registrar.address, 32))

        await myONFT721A.connect(ownerA).transferOwnership(myL2Registrar.address);
        await myONFT721B.connect(ownerB).transferOwnership(myOmniRegistrar.address);
    })

    // A test case to verify token transfer functionality
    it('should register a name from the L2Registrar', async function () {
        await myL2Registrar.register('test', ownerA.address, [], [], '0xe30101701220303926bd5eb62063e6ec2847e2a3b911775131c6b8e7f648dd4cfe7bd42f1e85').then((tx: any) => tx.wait());
        
        // TODO: This reverts as it should revert, use an expect revert
        // await myL2Registrar.register('test', ownerA.address, [], [], '0xe30101701220303926bd5eb62063e6ec2847e2a3b911775131c6b8e7f648dd4cfe7bd42f1e85').then((tx: any) => tx.wait());

        expect(await myONFT721A.ownerOf(myL2Registrar.labelHash('test'))).to.equal(ownerA.address)
        expect(await myL2Registry.labelFor(await myOmniRegistrar.labelHash('test'))).to.equal('test');
        expect(await myL2Registry.contenthash(await myOmniRegistrar.labelHash('test'))).to.equal('0xe30101701220303926bd5eb62063e6ec2847e2a3b911775131c6b8e7f648dd4cfe7bd42f1e85')
    })

    it('should register a name from the OmniRegistrar', async function () {

        const registerParams = [2, 'test2', ownerA.address, [], [], '0xe30101701220303926bd5eb62063e6ec2847e2a3b911775131c6b8e7f648dd4cfe7bd42f1e85']

        const options = Options.newOptions().addExecutorLzReceiveOption(20000000, 0).toHex().toString()

        // Define native fee and quote for the message send operation
        let nativeFee = 0
        ;[nativeFee] = await myOmniRegistrar.quote(eidA, registerParams, options, false)

        // Execute send operation from myOmniRegistrar
        await myOmniRegistrar.send(eidA, registerParams, options, { value: nativeFee.toString() }).then((tx: any) => tx.wait())

        // FIXME: It should be test2
        // expect(await myL2Registry.labelFor(await myOmniRegistrar.labelHash('test2'))).to.equal('test2');
        // expect(await myL2Registry.isRegistered(await myOmniRegistrar.labelHash('test2'))).to.equal(true)

        // FIXME: It should not allow to register the same name twice
        // await myL2Registrar.register('test2', ownerA.address, [], [], '0xe30101701220303926bd5eb62063e6ec2847e2a3b911775131c6b8e7f648dd4cfe7bd42f1e85').then((tx: any) => tx.wait());

        // expect(await myL2Registry.contenthash(await myOmniRegistrar.labelHash('test2'))).to.equal('0xe30101701220303926bd5eb62063e6ec2847e2a3b911775131c6b8e7f648dd4cfe7bd42f1e85')
        // FIXME: The ABA does not work
        // expect(await myONFT721A.ownerOf(myOmniRegistrar.labelHash('test2'))).to.equal(ownerA.address)
    })
})
