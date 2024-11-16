// Get the environment configuration from .env file
//
// To make use of automatic environment setup:
// - Duplicate .env.example file and name it .env
// - Fill in the environment variables
import 'dotenv/config'

import 'hardhat-deploy'
import 'hardhat-contract-sizer'
import '@nomiclabs/hardhat-ethers'
import '@nomicfoundation/hardhat-verify'
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
                    viaIR: true,
                },
            },
        ],
    },
    networks: {
        'celo': {
            eid: EndpointId.CELO_V2_MAINNET,
            url: `https://forno.celo.org`,
            accounts,
        },
        'scroll': {
            eid: EndpointId.SCROLL_V2_MAINNET,
            url: `https://scroll-mainnet.g.alchemy.com/v2/${vars.get('ALCHEMY_API_KEY')}`,
            accounts,
        },
        'morph': {
            eid: EndpointId.MORPH_V2_MAINNET,
            url: `https://rpc-quicknode.morphl2.io`,
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
    etherscan: {
        apiKey: {
            celo: 'anything',
            scroll: 'anything',
            morph: 'anything',
        },
        customChains: [
            {
                network: "celo",
                chainId: 42220,
                urls: {
                    apiURL: "https://explorer.celo.org/mainnet/api",
                    browserURL: "https://explorer.celo.org/mainnet",
                },
            },
            {
                network: 'scroll',
                chainId: 534352,
                urls: {
                    apiURL: 'https://scroll.blockscout.com/api/',
                    browserURL: 'https://scroll.blockscout.com/',
                },
            },
            {
                network: 'morph',
                chainId: 2818,
                urls: {
                  apiURL: 'https://explorer-api.morphl2.io/api',
                  browserURL: 'https://explorer.morphl2.io/',
                },
            },
        ],
    },
}

export default config
