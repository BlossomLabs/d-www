# Omniname Contracts

:warning: ** This code is currently under audit and should not yet be used in production. **

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
```

More information about available CLI arguments can be found using the `--help` flag:

```bash
npx hardhat lz:deploy --help
```

By following these steps, you can focus more on creating innovative omnichain solutions and less on the complexities of cross-chain communication.
