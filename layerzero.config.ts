import { EndpointId } from '@layerzerolabs/lz-definitions'
import { ExecutorOptionType } from '@layerzerolabs/lz-v2-utilities'

import type { OAppEdgeConfig, OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const celoContract: OmniPointHardhat = {
    eid: EndpointId.CELO_V2_MAINNET,
    contractName: 'MyONFT721',
}

const scrollContract: OmniPointHardhat = {
    eid: EndpointId.SCROLL_V2_MAINNET,
    contractName: 'MyONFT721',
}

const morphContract: OmniPointHardhat = {
    eid: EndpointId.MORPH_V2_MAINNET,
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
            contract: celoContract,
        },
        {
            contract: morphContract,
        },
    ],
    connections: [
        {
            from: scrollContract,
            to: celoContract,
            config: DEFAULT_EDGE_CONFIG,
        },
        {
            from: scrollContract,
            to: morphContract,
            config: DEFAULT_EDGE_CONFIG,
        },
        {
            from: celoContract,
            to: scrollContract,
            config: DEFAULT_EDGE_CONFIG,
        },
        {
            from: celoContract,
            to: morphContract,
            config: DEFAULT_EDGE_CONFIG,
        },
        {
            from: morphContract,
            to: celoContract,
            config: DEFAULT_EDGE_CONFIG,
        },
        {
            from: morphContract,
            to: scrollContract,
            config: DEFAULT_EDGE_CONFIG,
        },
    ],
}

export default config
