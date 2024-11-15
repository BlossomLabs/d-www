import { EndpointId } from '@layerzerolabs/lz-definitions'
import { ExecutorOptionType } from '@layerzerolabs/lz-v2-utilities'

import type { OAppEdgeConfig, OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const sepoliaContract: OmniPointHardhat = {
    eid: EndpointId.SEPOLIA_V2_TESTNET,
    contractName: 'MyONFT721',
}

const scrollContract: OmniPointHardhat = {
    eid: EndpointId.SCROLL_V2_TESTNET,
    contractName: 'MyONFT721',
}

const amoyContract: OmniPointHardhat = {
    eid: EndpointId.AMOY_V2_TESTNET,
    contractName: 'MyONFT721',
}

const DEFAULT_EDGE_CONFIG: OAppEdgeConfig = {
    enforcedOptions: [
        {
            msgType: 1,
            optionType: ExecutorOptionType.LZ_RECEIVE,
            gas: 100_000,
            value: 0,
        },
        {
            msgType: 2,
            optionType: ExecutorOptionType.COMPOSE,
            index: 0,
            gas: 100_000,
            value: 0,
        },
    ],
}

const config: OAppOmniGraphHardhat = {
    contracts: [
        {
            contract: scrollContract,
        },
        {
            contract: sepoliaContract,
        },
        {
            contract: amoyContract,
        },
    ],
    connections: [
        {
            from: scrollContract,
            to: sepoliaContract,
            config: DEFAULT_EDGE_CONFIG,
        },
        {
            from: scrollContract,
            to: amoyContract,
            config: DEFAULT_EDGE_CONFIG,
        },
        {
            from: sepoliaContract,
            to: scrollContract,
            config: DEFAULT_EDGE_CONFIG,
        },
        {
            from: sepoliaContract,
            to: amoyContract,
            config: DEFAULT_EDGE_CONFIG,
        },
        {
            from: amoyContract,
            to: sepoliaContract,
            config: DEFAULT_EDGE_CONFIG,
        },
        {
            from: amoyContract,
            to: scrollContract,
            config: DEFAULT_EDGE_CONFIG,
        },
    ],
}

export default config
