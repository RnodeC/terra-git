# Terra-ble

Ansible scripts to automate deployment of Terra core and oracle feeder

## Setup

You will need:
* At least one rhel/centos machine of appropriate dimensions, which you can reach via ssh
* A client machine to run this ansible script from (these two machines can be the same if you'd like, just use `ansible_connection=local` in your `inventory.ini` file)
  * [`ansible` must be installed here](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* To create an `inventory.ini` file.  Use `inventory.ini.sample` to get started
* To create an `ansible_vars.yaml` file. Use `ansible_vars.yaml.sample` to get started
* To encrypt a few files/variables with `ansible-vault` (or you can leave them unencrypted..).  Details/instructions are in the `ansible_vars.yaml.sample`


If you are using ansible_vault, here is how you can create an ansible password file.  this is a plaintext file used for convenience.  you can alternatively just store this in your hand and asked to be prompted for your password in all ansible-vault commands  
```bash
echo "myansiblevaultpassword" > $HOME/.ansible_vault
```  

## Execution

```bash
# selectively choose one, more, or all tags to include.  this example shows all tags
ansible-playbook -e @ansible_vars.yaml --vault-password-file $HOME/.ansible_vault terra-deploy.yaml --tags "common,get-chain-data,node,validator,price-server,feeder"
```


## Terracli commands to run post execution 

Don't do anything until your node has caught up:  `terracli status | jq .sync_info.catching_up`
> (that command ^ assumes you have `terracli` configured.  i.e. you have done `terracli config node http://<terrad node>:26657` and `terracli config trust-node true`)


#### Register Validator

This is how you actually join your node to the network as an official validator.  You submit this special transaction.  It is saying that **this wallet** (`--from`) would like to announce that **this node** (`--pubkey`) is now a validator, and we call ourselves `--moniker`.  
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

#### Delegate vote permission to feeder wallet
This part cannot be done until after your validator has joined the network (registered as a validator).  Here we are telling the network that we would like (and we authorize) *this* oracle instance to vote on the behalf of our validator.  

```bash
terracli tx oracle set-feeder $FEEDER_ADDRESS --from=$VALIDATOR --chain-id $NETWORK --fees="30000uluna"
```
* `FEEDER_ADDRESS`: public address associated with the wallet you are using for the feeder.  The same one that you used when you ran 'npm start update-key' earlier.  It asked you for a bip39 mnemonic... 
* `VALIDATOR`: the name of the wallet on your local client that the is being used for your validator
* `NETWORK`: `tequila-0004`, `columbus-4`, etc

## ToDo

This playbook is still incomplete.  I would like this to support a full Sentry-style architecture.  There are a few nuances to think through though in order to support single node as well.  


## Ansible-Galaxy Dependencies

```bash

ansible-galaxy collection install ansible.posix community.general
```