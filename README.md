# Omniname Contracts

:warning: ** THIS IS AN EXPERIMENTAL PROJECT. DO NOT USE THIS CODE IN PRODUCTION. **

## 1) Developing Contracts

#### Installing dependencies

We recommend using `bun` as a package manager (but you can of course use a package manager of your choice):

```bash
bun install
```

#### Compiling your contracts

```bash
bun compile
```

#### Running tests

```bash
bun run test
```

## 2) Deploying Contracts

Set up deployer wallet/account:

- `npx hardhat vars set PRIVATE_KEY`

- Fund this address with the corresponding chain's native tokens you want to deploy to.

To deploy your contracts to your desired blockchains, run the following command in your project's folder:

```bash
npx hardhat lz:deploy
npx hardhat verify --network <network> <contract-address> <constructor-arguments> # optional
npx hardhat lz:oapp:wire --oapp-config layerzero.config.ts
```

## 3) Contracts deployments

**Scroll**

| Contract | Address |
| -------- | -------- |
| L2Registrar | [0x39065fc36F04E9AB040d55332ff28422C48e63d2](https://scroll.blockscout.com/address/0x39065fc36F04E9AB040d55332ff28422C48e63d2) |
| L2Registry | [0xeB39C38a4d1D3E5C1ACC45aE0896b65c6De2ad57](https://scroll.blockscout.com/address/0xeB39C38a4d1D3E5C1ACC45aE0896b65c6De2ad57) |
| OmniName | [0x3d8Ec641793c3F5bDE837bDA7772Ec6A77D1da32](https://scroll.blockscout.com/address/0x3d8Ec641793c3F5bDE837bDA7772Ec6A77D1da32) |

**Celo**

| Contract | Address |
| -------- | -------- |
| OmniRegistrar | [0x088b8FBB4559DdAABE6BDA04A7f3165957f4Fe61](https://explorer.celo.org/mainnet/address/0x088b8FBB4559DdAABE6BDA04A7f3165957f4Fe61) |
| OmniName | [0xd77D4d13C17d05357540B04979D875Ba29f4Fcbb](https://explorer.celo.org/mainnet/address/0xd77D4d13C17d05357540B04979D875Ba29f4Fcbb) |

- You can register a subdomain by calling `register` on the `L2Registrar` contract with the following params: [EVMcrispr script](https://evmcrispr.com/#/terminal/QmcVBK2pMhULNfmaEJhPUDjYeUEHGxZoS2DxLcdSBhQ88v).

