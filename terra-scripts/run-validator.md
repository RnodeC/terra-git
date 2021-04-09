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


## Config changes specific to participate in this network

```bash
sed -i "s|minimum-gas-prices =.*|minimum-gas-prices = \"$GASPRICE\"|" .terrad/config/app.toml
sed -i "s|seeds =.*|seeds = \"$SEEDNODES\"|" .terrad/config/config.toml
```
* `GASPRICE`: need to reference the network repo mentioned above to get this value.  For example on testnet would be:  `"0.01133uluna,0.15uusd,0.104938usdr,169.77ukrw,428.571umnt,0.125ueur,0.98ucny,16.37ujpy,0.11ugbp,10.88uinr,0.19ucad,0.14uchf,0.19uaud,0.2usgd,4.62uthb"`
* `SEEDNODES`: need to reference the network repo mentioned above to get this value.  For example on testnet would be: `341f51bf381566dfef0fc345c2aa882cbeebd320@public-seed2.terra.dev:36656`


## IF THIS IS A VALIDATOR...

Remember that our validator should never see the outside world - the idea is that it only would ever communicate with the sentries.  So to do this, we need to just make a few configuration changes to `~/.terrad/config/config.toml`.  Specifically, we need to set:

Reference: https://forum.cosmos.network/t/sentry-node-architecture-overview/454

```
pex = false
```
```
persistent_peers = <list of sentries>
```
```
addr_book_strict = false
```

Also, we need to make sure that this validator is using the correct signing key.  The two files of interest are `~/.terrad/config/priv_validator_key.json` and `~/.terrad/config/node_key.json`.  There can only be one signing key for your validator.  If this is first time setting up, then the one you got is ok.  

Wherever you securely keep these files, just make sure they are in place on this validator node.  



## IF THIS IS A SENTRY...

Our sentries on the other hand have public IPs and are seeing very much of the outside world.  Here are the configuration changes to `~/.terrad/config/config.toml` that need to be set for sentries:

```
pex = true
```
```
persistent_peers = <validator node, optionally other sentry nodes>
```
```
addr_book_strict = false
```
```
private_peer_ids	<validator node>
```

## Start up node
```bash
echo; echo "[INFO] Starting terrad node"
sudo systemctl start terrad
sudo systemctl start lcd
```