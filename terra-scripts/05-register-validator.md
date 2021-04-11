
# Join Validator to Network

Once your validator and sentries are alive and well, you can submit a simple transaction to the protocol to signal to the network that one of your full nodes (your validator) is officially joining as an actual Validator.  

These commands are all going to be run from your local client - not from your validator nor sentry nodes.  We are going to be working with keys here and these are all kept secure in one place (best to avoid letting sensitive, valuable data leave our local environment whenever we can help it).  

## Setup
To save some space on these commands and some time down the road, we can set a few global configuration options for our `terracli` tool.  
```bash
terracli config chain-id $NETWORK
```
* `NETWORK`: `tequila-0004`, `columbus-4`, etc

Some of the commands that `terracli` operates just execute locally (i.e. `terracli keys..`).  But, some need to query the network.  Such as the `terracli query` subcommand.  This means that they will need to reach *a* node at it's RPC interface (port 26657).  One neat and simple way to accomplish this is to use ssh port forwarding to send all traffic that hits our clients' port 26657 to the validators 26657.  (we should be able to use our sentries instead if we want, but we know the validator will always be there).  Then, we will be able to use `localhost:26657` for `terracli query`, `terracli tx`, etc commands.
```bash
gcloud compute ssh $VALIDATOR_INSTANCE_NAME --zone $VALIDATOR_INSTANCE_ZONE --tunnel-through-iap -- -fNT -L 26657:127.0.0.1:26657 #forward localhost:26657 to validator
terracli config node tcp://localhost:26657
terracli config trust-node true
```
* `VALIDATOR_INSTANCE_NAME`: The name you assigned your validator (`gcloud compute instances list`)
* `VALIDATOR_INSTANCE_ZONE`: The zone your validator is running in

> Note: all `gcloud compute ssh` **`--tunnel-through-iap`** commands assume that you have enabled this feature in your GCP environment

> Note: shoutout to pete's fan club for the ssh tunnel idea  

## Register Validator

```bash
terracli tx staking create-validator \
	--pubkey $VALIDATOR_PUBLIC_KEY \
	--amount $AMOUNT \
	--from $VALIDATOR_WALLET_NAME \
	--commission-rate 0.1 \
	--commission-max-rate 0.2 \
	--commission-max-change-rate="0.05" \
	--min-self-delegation "1" \
	--moniker $MONIKER \
	--gas-prices "1.5uluna" \
	--gas-adjustment "1.4" 
```
* `VALIDATOR_PUBLIC_KEY`: this is the public key you get from the validator node itself (`terrad tendermint show-validator`).  It corresponds to the `.terrad/config/priv_validator_key.json` file on your validator node.  It is your actual nodes signing key identity.  i.e. `terravalconspubxxxx`
* `VALIDATOR_WALLET_NAME`:  the wallet that you want to be in control of any funds sent to this validator (your rewards/commission).  Local here on your client machine.  This should just be a plaintext string that `terracli` is aware of (`terracli keys list`)
* `MONIKER`: The public facing name you want to give your Validator.  `RnodeC`
* `AMOUNT`: how much to add to validator wallet... i.e. `4000000000uluna` (which is 4000 luna)

## Delegate Luna from your wallet to your validator?

```bash
terracli tx staking delegate $VALIDATOR_ADDRESS $AMOUNT --fees 30000uluna --from $WALLET
```
* `VALIDATOR_ADDRESS`: the bech encoded address of the wallet used to back your validator (`terravaloperxxxx`).  Use `terracli keys show -a --bech val VALIDATOR_WALLET_NAME` to get this. 
* `AMOUNT`: how much to delegate... i.e. `4000000000uluna` (which is 4000 luna)
* `WALLET`: the wallet that is holding the funds we want to delegate.  This should just be a plaintext string that `terracli` is aware of (`terracli keys list`)