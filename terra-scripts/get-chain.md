# Download chain quick sync file

Thank you to the chainlayer team for this...


```bash
NETWORK=tequila-0004
SYNCURL=https://get.quicksync.io
DATADIR=/terradata # better have a lot of capacity here
CHAINFILENAME=tequila-4-default.20210401.0940 # reference https://terra.quicksync.io/# to find latest file for you


echo; echo "[INFO] Downloading ${NETWORK} chain ${CHAINFILENAME}.tar.lz4 to ${DATADIR}"
aria2c -x5 ${SYNCURL}/${CHAINFILENAME}.tar.lz4 -d ${DATADIR}
wget https://raw.githubusercontent.com/chainlayer/quicksync-playbooks/master/roles/quicksync/files/checksum.sh -O ${DATADIR}/checksum.sh
chmod +x ${DATADIR}/checksum.sh
wget https://get.quicksync.io/${CHAINFILENAME}.tar.lz4.checksum -O ${DATADIR}/${CHAINFILENAME}.tar.lz4.checksum
curl -s https://lcd.terra.dev/txs/`curl -s https://get.quicksync.io/${CHAINFILENAME}.tar.lz4.hash`|jq -r '.tx.value.memo'|sha512sum -c
#./checksum.sh ${DATADIR}/${CHAINFILENAME}.tar.lz4
lz4 -d ${DATADIR}/${CHAINFILENAME}.tar.lz4 ${DATADIR}/${CHAINFILENAME}.tar
echo "[INFO] Removing ${DATADIR}/${CHAINFILENAME}.tar.lz4"
rm -f ${DATADIR}/${CHAINFILENAME}.tar.lz4
tar xf ${DATADIR}/${CHAINFILENAME}.tar -C ${DATADIR}/${NETWORK}
echo "[INFO] Removing ${DATADIR}/${CHAINFILENAME}.tar"
rm -f ${DATADIR}/${CHAINFILENAME}.tar
chown -R 1000:1000 terradata/${NETWORK}
```


## Manage chaindata disks
```bash
#create a disk with quicksync snapshot from chainlayer
DISK_NAME=chaindata
ORIG_ZONE=us-central1-a
PROJECT_ID=terra-309517
KMS_KEY=projects/terra-309517/locations/global/keyRings/jo/cryptoKeys/jo-key
gcloud  compute --project=terra-$PROJECT_ID instances create testing \
	--zone=$ORIG_ZONE \
	--machine-type=e2-highcpu-8 \
	--network=default \
	--subnet=default \
	--image-family=rhel-7 \
	--image-project=rhel-cloud \
	--disk=name=$DISK_NAME,scope=regional \
................
................
script for downloading chain
................
................
gcloud compute instances delete...


#create snapshot from that disk
gcloud compute disks snapshot $DISK_NAME --zone=$ORIG_ZONE --snapshot-names=$DISK_NAME-snapshot 

#create new disk from snapshot in target zone
DEST_ZONE=us-central1-a
gcloud compute disks create $DISK_NAME --source-snapshot=$DISK_NAME-snapshot  --zone=$DEST_ZONE --kms-key=$KMS_KEY

# get selflink to use in tfvars
gcloud compute disks describe $DISK_NAME --format=value"(selfLink)" --zone $DEST_ZONE
```
