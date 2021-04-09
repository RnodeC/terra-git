# Oracle Feeder Configuration

- These snippets are intended for reference purposes, not to be copy and pasted without reading, understanding, and editing to suit your environment
- The assumption here is that this is a standalone oracle server that will run both the price feeder and the price server daemons

Reference: 
- https://github.com/petes-fan-club/terra-scripts
- https://github.com/terra-project/oracle-feeder
- https://docs.terra.money/validator/setup.html#delegate-feeder-consent


## Create oracle wallet
Do this from a local client, not this oracle machine.  You want to protect these keys like you would any other.  
```bash
terracli keys add oracle #save this mnemonic! 
terracli keys show oracle
```

## Update OS and add a few packages
Now over on the machine you are using as your oracle you can start setting things up.  
```bash
echo; echo "[INFO] Updating os and installing a few dependencies"
sudo yum update -y
sudo yum install jq git wget gcc-c++ make gcc -y
```

#### ...a node package later on requires a newer version of git, for some reason this is best way to get it
```bash
sudo yum install http://opensource.wandisco.com/rhel/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm -y
sudo rpm --import  http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco
sudo yum upgrade git -y
sudo rm -f /etc/yum.repos.d/wandisco-git.repo #get rid of this insecure repo now that we have what we need from it
```

## Adjust nofiles kernel param
This is probably not necessary, but with only one application here, who cares.
```bash
echo; echo "[INFO] Adjusting nofiles kernel param"
sudo bash -c "cat > /etc/security/limits.d/terrad.conf << EOF
# /etc/security/limits.conf

*                soft    nofile          65535
*                hard    nofile          65535
EOF"
```

## Create oracleuser
```bash
sudo useradd -u 88888 -G 1000 oracleuser #supplementary (special gcp) group 1000 gives us sudo
```

## Become oracleuser
```bash
sudo su - oracleuser
```

## Install nodejs
```bash
echo; echo "[INFO] Installing node"
VERSION=v14.16.0
DISTRO=linux-x64
sudo mkdir -p /usr/local/lib/nodejs
wget -O - https://nodejs.org/dist/v14.16.0/node-$VERSION-$DISTRO.tar.xz | sudo tar xJ -C /usr/local/lib/nodejs
export PATH=/usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin:$PATH
echo "export PATH=/usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin:$PATH" >> /home/oracleuser/.bashrc
```

## Setup app dir
```bash
sudo mkdir /opt/terra
sudo chown oracleuser:oracleuser /opt/terra
pushd /opt/terra
```

## Clone terra oracle-feeder project
```bash
git clone https://github.com/terra-project/oracle-feeder
```

## Configure and prep feeder
```bash
pushd oracle-feeder/feeder
npm install
npm start update-key
# follow prompts to enter your local encryption key and bip39 mnemonic associated with your oracle wallet
popd
```

## Configure and prep price-server
```bash
pushd oracle-feeder/price-server
gcloud secrets versions access X --secret="xxx" > config/default.js # this default.js has my api key in it.. you will copy the sample provided, and visit one of the providers mentioned in order to get your own api key
[ ! -f ./config/default.js ] && echo "[ERROR] price-server config file config/default.js not found.  Exiting" && exit 1
npm install
popd
```

## Install price-server systemd unit file
```bash
sudo bash -c "cat > /etc/systemd/system/price-server.service << EOF
[Unit]
Description=Terra Oracle Feeder
After=network.target

[Service]
Type=simple
User=oracleuser
WorkingDirectory=/opt/terra/oracle-feeder/price-server
ExecStart=/opt/terra/oracle-feeder/price-server/run-price-server.sh
Restart=on-failure
RestartSec=5s
Environment="PATH=/usr/local/lib/nodejs/node-v14.16.0-linux-x64/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin"

[Install]
WantedBy=multi-user.target

[Service]
LimitNOFILE=65535

EOF"
```


## Create price-server run script
```bash
bash -c "cat > /opt/terra/oracle-feeder/price-server/run-price-server.sh << EOF
#!/bin/bash

/usr/local/lib/nodejs/node-v14.16.0-linux-x64/bin/npm run start

EOF"
```

## Install price-feeder systemd unit file
```bash
sudo bash -c "cat > /etc/systemd/system/price-feeder.service << EOF
[Unit]
Description=Terra Oracle Feeder
After=network.target

[Service]
Type=simple
User=oracleuser
WorkingDirectory=/opt/terra/oracle-feeder/feeder
EnvironmentFile=/opt/terra/oracle-feeder/feeder/price-feeder.env
ExecStart=/opt/terra/oracle-feeder/feeder/run-price-feeder.sh
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target

[Service]
LimitNOFILE=65535

EOF"
```


## Create price-feeder env vars file
```bash
bash -c "cat > /opt/terra/oracle-feeder/feeder/price-feeder.env << EOF
#!/bin/bash


VALIDATOR_ADDRESS=terravaloper1zknku7qu5dac2w40hdg4ff6hp9rwre9z07csds  
ORACLE_PASS=testtest
PATH=/usr/local/lib/nodejs/node-v14.16.0-linux-x64/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin

EOF"
```

## Create price-feeder run script
```bash
bash -c "cat > /opt/terra/oracle-feeder/feeder/run-price-feeder.sh << EOF
#!/bin/bash

npm start vote -- \\
   	--source http://localhost:8532/latest \\
   	--lcd http://validator:1317 \\
   	--chain-id tequila-0004 \\
 	--denoms sdr,krw,usd,mnt,eur,cny,jpy,gbp,inr,cad,chf,hkd,aud,sgd \\
	--validator "\${VALIDATOR_ADDRESS}" \\
	--password "\${ORACLE_PASS}" \\
	--gas-prices 169.77ukrw

EOF"
```

## Update price feeder /etc/hosts with validator hostname
```bash
sudo bash -c "cat >> /etc/hosts << EOF
$VALIDATOR_PRIVATE_IP validator

EOF"
```


## Ensure permissions aren't going to bite us
```bash
sudo chown oracleuser:oracleuser /opt/terra -R
sudo chmod 700 /opt/terra -R
```


## Delegate permission
This part cannot be done until after your validator has joined the network.  Here we are telling the network that we would like (and we authorize) *this* oracle instance to vote on the behalf of our validator.  

This command should be run on your client machine.  

```bash
terracli tx oracle set-feeder $FEEDER_ADDRESS --from=$VALIDATOR --chain-id tequila-0004 --fees="30000uluna"
```
* `FEEDER_ADDRESS`: public address associated with the wallet you are using for the feeder.  The same one that you used when you ran 'npm start update-key' earlier.  It asked you for a bip39 mnemonic... 
* `VALIDATOR`: the name of the 

## Allocate funds in appropriate demonination, and delegate permission 
This feeder wallet needs Luna to pay the gas for all his transactions.  Lots and lots of transaction.  Very miniscule gas fees, but you don't want it to run dry or you will start missing votes!
```bash
terracli tx send $FROM_ADDRESS $TO_ADDRESS $AMOUNT --fees 30000uluna
terracli tx market swap $AMOUNT ukrw --from=$WALLET
```
* `FROM_ADDRESS`: if you are on your client machine where this wallet lives, this can just be the public address of the wallet with the funds
* `TO_ADDRESS`: if you are on your client machine where this wallet lives, this can just be the public address of the wallet for the funds
* `AMOUNT`: `10000000uluna` = 10 Luna.  


## Start services
```bash
sudo systemctl daemon-reload
sudo systemctl enable price-server
sudo systemctl start price-server
sleep 60
sudo systemctl enable price-feeder
sudo systemctl start price-feeder
```
And check on them...
```bash
sudo journalctl -u price-feeder
sudo journalctl -u price-server
```
