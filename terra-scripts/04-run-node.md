# Run Validator

You should already be `terrauser` here... (`sudo su - terrauser`)

## Initialize terrad
This command builds out default config files in `~/.terrad`
```bash
terrad init --chain-id $NETWORK $MONIKER 
```
* `NETWORK`: `tequila-0004`, `columbus-4`, etc
* `MONIKER`: The public facing name you want to give your Validator.  `RnodeC`

## Create a symlink from .terrad/data to the local directory where you set up your quicksync-ed chain
```bash 
rm -rf .terrad/data
ln -s /terradata/${NETWORK}/data .terrad/data
```

## Download address book and genesis file for this network
Address book has contact info (ip address) for all currently participating nodes in this network.  Saves the node the trouble of building this out on its own.  Genesis file is the root of all blocks - pretty important for validating current state.  
```bash
rm -f .terrad/config/genesis.json
wget -q $GENESISFILE -O .terrad/config/genesis.json

rm -f .terrad/config/addrbook.json
wget -q $ADDRBOOK -O .terrad/config/addrbook.json
```
> Find mainnet files here:  https://github.com/terra-project/mainnet
> Find testnet files here:  https://github.com/terra-project/testnet


## IF THIS IS A VALIDATOR...

Remember that our validator should never see the outside world - the idea is that it only would ever communicate with the sentries.  So to do this, we need to just make a few configuration changes to `~/.terrad/config/config.toml`.  Specifically, we need to set:

```
pex = false
```
```
persistent_peers = <list of sentries>
```
> The format for a "peer" is `<nodeid>@<ip>:<port>`.  `nodeid` can be found per node by running `terrad tendermint show-node-id`
```
addr_book_strict = false
```

Here are the configuration changes to `~/.terrad/config/app.toml` that need to be set for the validator:
MAINNET GAS:
```
minimum-gas-prices = "0.01133uluna,0.15uusd,0.104938usdr,169.77ukrw,428.571umnt,0.125ueur,0.98ucny,16.37ujpy,0.11ugbp,10.88uinr,0.19ucad,0.14uchf,0.19uaud,0.2usgd,4.62uthb"
```

Also, we need to make sure that this validator is using the correct signing key.  The two files of interest are `~/.terrad/config/priv_validator_key.json` and `~/.terrad/config/node_key.json`.  There can only be one signing key for your validator.  If this is first time setting up, then the one you got is ok.  

Wherever you securely keep these files, just make sure they are in place on this validator node.  

Reference: https://forum.cosmos.network/t/sentry-node-architecture-overview/454


## IF THIS IS A SENTRY...

Our sentries on the other hand have public IPs and are seeing very much of the outside world.  Here are the configuration changes to `~/.terrad/config/config.toml` that need to be set for sentries:

```
pex = true
```
```
persistent_peers = <validator node, optionally other sentry nodes>
```
> The format for a "peer" is `<nodeid>@<ip>:<port>`.  `nodeid` can be found per node by running `terrad tendermint show-node-id`
```
addr_book_strict = false
```
```
private_peer_ids	<validator node>
```
> The format for a "peer" is `<nodeid>@<ip>:<port>`.  `nodeid` can be found per node by running `terrad tendermint show-node-id`

MAINNET SEEDS:
```
seeds = "87048bf71526fb92d73733ba3ddb79b7a83ca11e@public-seed.terra.dev:26656,b5205baf1d52b6f91afb0da7d7b33dcebc71755f@public-seed2.terra.dev:26656,5fa582d7c9931e5be8c02069d7b7b243c79d25bf@seed.terra.de-light.io:26656"
```

Here are the configuration changes to `~/.terrad/config/app.toml` that need to be set for sentries:
MAINNET GAS:
```
minimum-gas-prices = "0.01133uluna,0.15uusd,0.104938usdr,169.77ukrw,428.571umnt,0.125ueur,0.98ucny,16.37ujpy,0.11ugbp,10.88uinr,0.19ucad,0.14uchf,0.19uaud,0.2usgd,4.62uthb"
```

Reference: https://forum.cosmos.network/t/sentry-node-architecture-overview/454


## Start up node
```bash
sudo systemctl start terrad
sudo systemctl start lcd
```