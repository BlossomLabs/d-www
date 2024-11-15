// Get the environment configuration from .env file
//
// To make use of automatic environment setup:
// - Duplicate .env.example file and name it .env
// - Fill in the environment variables
import 'dotenv/config'

import 'hardhat-deploy'
import 'hardhat-contract-sizer'
import '@nomiclabs/hardhat-ethers'
import '@layerzerolabs/toolbox-hardhat'
import { HardhatUserConfig, HttpNetworkAccountsUserConfig } from 'hardhat/types'

import { EndpointId } from '@layerzerolabs/lz-definitions'

import { vars } from 'hardhat/config'

// Set your preferred authentication method
//
// If you prefer using a mnemonic, set a MNEMONIC environment variable
// to a valid mnemonic
// If you prefer to be authenticated using a private key, set a PRIVATE_KEY environment variable


const accounts: HttpNetworkAccountsUserConfig | undefined = vars.has('MNEMONIC')
    ? { mnemonic: vars.get('MNEMONIC') }
    : vars.has('PRIVATE_KEY')
      ? [vars.get('PRIVATE_KEY')]
      : undefined

if (accounts == null) {
    console.warn(
        'Could not find MNEMONIC or PRIVATE_KEY hardhat variables. It will not be possible to execute transactions in your example.'
    )
}

const config: HardhatUserConfig = {
    paths: {
        cache: 'cache/hardhat',
    },
    solidity: {
        compilers: [
            {
                version: '0.8.22',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    networks: {
        'sepolia-testnet': {
            eid: EndpointId.SEPOLIA_V2_TESTNET,
            url: `https://eth-sepolia.g.alchemy.com/v2/${vars.get('ALCHEMY_API_KEY')}`,
            accounts,
        },
        'scroll-testnet': {
            eid: EndpointId.SCROLL_V2_TESTNET,
            url: `https://scroll-sepolia.g.alchemy.com/v2/${vars.get('ALCHEMY_API_KEY')}`,
            accounts,
        },
        'amoy-testnet': {
            eid: EndpointId.AMOY_V2_TESTNET,
            url: `https://polygon-amoy.g.alchemy.com/v2/${vars.get('ALCHEMY_API_KEY')}`,
            accounts,
        },
        hardhat: {
            // Need this for testing because TestHelperOz5.sol is exceeding the compiled contract size limit
            allowUnlimitedContractSize: true,
        },
    },
    namedAccounts: {
        deployer: {
            default: 0, // wallet address of index[0], of the mnemonic in .env
        },
    },
}

export default config
