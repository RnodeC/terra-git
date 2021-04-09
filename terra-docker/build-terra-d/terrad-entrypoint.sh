
#!/bin/sh


echo "[INFO] Launching entrypoint"

DATADIR=/terradata

[ -z $MONIKER ] && echo "[ERROR] MONIKER is required.  Exiting." && exit 1
[ -z $NETWORK ] && echo "[ERROR] NETWORK is required.  Exiting." && exit 1

echo; echo "[INFO] Initializing for moniker: $MONIKER" 
terrad init --chain-id $NETWORK $MONIKER 

echo; echo "[INFO] Creating symlink from .terrad/data to /data $DATADIR since docker won't preserve permissions when we mount at .terrad/data for some reason" 
rm -rf .terrad/data
ln -s $DATADIR .terrad/data


echo; echo "[INFO] Bootstrapping for network: $NETWORK" 

case "${NETWORK}" in 
    "columbus-4") 
      GENESISFILE=https://columbus-genesis.s3-ap-northeast-1.amazonaws.com/genesis.json
      ADDRBOOK=https://network.terra.dev/addrbook.json
      GASPRICE="0.01133uluna,0.15uusd,0.104938usdr,169.77ukrw,428.571umnt,0.125ueur,0.98ucny,16.37ujpy,0.11ugbp,10.88uinr,0.19ucad,0.14uchf,0.19uaud,0.2usgd,4.62uthb"
      SEEDNODES="5d9b8ac70000bd4ab1de3ccaf85eb43f8e315146@seed.terra.delightlabs.io:26656,6d8e943c049a80c161a889cb5fcf3d184215023e@public-seed2.terra.dev:26656,87048bf71526fb92d73733ba3ddb79b7a83ca11e@public-seed.terra.dev:26656"
      ;;
    "tequila-0004")
      GENESISFILE=https://raw.githubusercontent.com/terra-project/testnet/master/tequila-0004/genesis.json 
      ADDRBOOK=https://network.terra.dev/testnet/addrbook.json
      GASPRICE="0.15uluna,0.15uusd,0.1018usdr,178.05ukrw,431.6259umnt"
      SEEDNODES="341f51bf381566dfef0fc345c2aa882cbeebd320@public-seed2.terra.dev:36656"
      ;;
    *)
      echo; echo "[ERROR] ${NETWORK} not supported"
      exit 1
      ;;
esac 

# obtain address book and genesis for this network
DEST=.terrad/config/genesis.json
rm -f $DEST
echo; echo -e "[INFO] Obtaining genesis file:\n\t $GENESISFILE > $DEST"
wget -q $GENESISFILE -O $DEST

DEST=.terrad/config/addrbook.json
rm -f $DEST
echo; echo -e "[INFO] Obtaining address book:\n\t $ADDRBOOK > $DEST"
wget -q $ADDRBOOK -O $DEST

# config changes specific to participate in this network
APP=.terrad/config/app.toml
CONFIG=.terrad/config/config.toml
echo; echo -e "[INFO] Setting Seed Nodes in $APP:\n\t $SEEDNODES"
sed -i "s|minimum-gas-prices =.*|minimum-gas-prices = \"$GASPRICE\"|" $APP

echo; echo -e "[INFO] Setting Min Gas Price in $CONFIG:\n\t $GASPRICE"
sed -i "s|seeds =.*|seeds = \"$SEEDNODES\"|" $CONFIG

echo; echo "[INFO] Starting terrad node"
terrad start

