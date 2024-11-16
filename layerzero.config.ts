import { EndpointId } from '@layerzerolabs/lz-definitions'
import { ExecutorOptionType } from '@layerzerolabs/lz-v2-utilities'

import type { OAppEdgeConfig, OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const celoOmniRegistrar: OmniPointHardhat = {
    eid: EndpointId.CELO_V2_MAINNET,
    contractName: 'OmniRegistrar',
}

const celoOmniName: OmniPointHardhat = {
    eid: EndpointId.CELO_V2_MAINNET,
    contractName: 'OmniName',
}

const scrollL2Registrar: OmniPointHardhat = {
    eid: EndpointId.SCROLL_V2_MAINNET,
    contractName: 'L2Registrar',
}

const scrollOmniName: OmniPointHardhat = {
    eid: EndpointId.SCROLL_V2_MAINNET,
    contractName: 'OmniName',
}

// const morphOmniRegistrar: OmniPointHardhat = {
//     eid: EndpointId.MORPH_V2_MAINNET,
//     contractName: 'OmniRegistrar',
// }

// const morphOmniName: OmniPointHardhat = {
//     eid: EndpointId.MORPH_V2_MAINNET,
//     contractName: 'OmniName',
// }

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
            contract: scrollOmniName,
        },
        {
            contract: scrollL2Registrar,
        },
        {
            contract: celoOmniName,
        },
        {
            contract: celoOmniRegistrar,
        },
        // {
        //     contract: morphOmniName,
        // },
        // {
        //     contract: morphOmniRegistrar,
        // },
    ],
    connections: [
        // OmniName are configured to be the same on all chains (Star topology)
        {
            from: scrollOmniName,
            to: celoOmniName,
            config: DEFAULT_EDGE_CONFIG,
        },
        // {
        //     from: scrollOmniName,
        //     to: morphOmniName,
        //     config: DEFAULT_EDGE_CONFIG,
        // },
        {
            from: celoOmniName,
            to: scrollOmniName,
            config: DEFAULT_EDGE_CONFIG,
        },
        // {
        //     from: celoOmniName,
        //     to: morphOmniName,
        //     config: DEFAULT_EDGE_CONFIG,
        // },
        // {
        //     from: morphOmniName,
        //     to: celoOmniName,
        //     config: DEFAULT_EDGE_CONFIG,
        // },
        // {
        //     from: morphOmniName,
        //     to: scrollOmniName,
        //     config: DEFAULT_EDGE_CONFIG,
        // },
        // L2Registrar - OmniRegistrar is configured with a Tree topology
        {
            from: scrollL2Registrar,
            to: celoOmniRegistrar,
            // config: DEFAULT_EDGE_CONFIG,
        },
        {
            from: celoOmniRegistrar,
            to: scrollL2Registrar,
            // config: DEFAULT_EDGE_CONFIG,
        },
        // {
        //     from: scrollL2Registrar,
        //     to: morphOmniRegistrar,
        //     // config: DEFAULT_EDGE_CONFIG,
        // },
        // {
        //     from: morphOmniRegistrar,
        //     to: scrollL2Registrar,
        //     // config: DEFAULT_EDGE_CONFIG,
        // },
    ],
}

export default config
