# Download chain quick sync file

Thank you to the chainlayer team for this...

The overall approach here is:
1. create a gcp instance with a large disk attached
2. download chaindata
3. delete instance
4. snapshot disk
5. create disks from that snapshot in target regions

## Step 1: New Instance  

Create Instance:
```bash
gcloud compute instances create quicksync \
	--image-family=ubuntu-1804-lts \
	--image-project=ubuntu-os-cloud    \
	--zone=us-central1-a \
	--machine-type n2-standard-2 \
	--create-disk=name=chaindata,size=1500GB,type=pd-ssd,auto-delete=no
```
> *using ubuntu here just because the apt repositories have aria2c package available*

SSH into it:
```bash
gcloud compute ssh quicksync
```
Config OS with necessary packages:
```bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install aria2 liblz4-tool wget jq git tmux -y
```
Set up directory where we download data to:
```bash
sudo mkdir /terradata
sudo mkfs -t ext4 /dev/sdb #double check this is the correct device first with `lsblk` command
sudo mount -t ext4 /dev/sdb /terradata
sudo chmod -R 777 /terradata
```

## Step 2: Download Chain Data
```bash
tmux # do this is in tmux in case you lose your shell
DATADIR=/terradata/columbus-4 # better have a lot of capacity here
CHAINFILENAME=columbus-4-default.20210409.0410 # reference https://terra.quicksync.io/# to find latest file for you
CHAINFILEURL=https://get.quicksync.io/${CHAINFILENAME}.tar.lz4 

pushd ${DATADIR}

set -e 

# download the file.  this takes a long time
aria2c -x5 ${CHAINFILEURL} 

# download the checksum script
wget https://raw.githubusercontent.com/chainlayer/quicksync-playbooks/master/roles/quicksync/files/checksum.sh -O checksum.sh
chmod +x checksum.sh

# download the checksum for this chain from quicksync
wget ${CHAINFILEURL}.checksum -O ${CHAINFILENAME}.checksum

# compare the hash of the chain you are downloading with the signed, onchain value that has been saved (I think?)
curl -s https://lcd.terra.dev/txs/`curl -s ${CHAINFILEURL}.hash`|jq -r '.tx.value.memo'|sha512sum -c

# run checksum script on downloaded file
./checksum.sh ${CHAINFILENAME}.tar.lz4

# unpack chain archive.  takes a long time
lz4 -d ${CHAINFILENAME}.tar.lz4 ${CHAINFILENAME}.tar
[ -f ${CHAINFILENAME}.tar ] && rm -f ${CHAINFILENAME}.tar.lz4
tar xf ${CHAINFILENAME}.tar 
rm -f ${CHAINFILENAME}.tar
popd

# make sure permissions won't bite us
chmod -R 777 $DATADIR
```
You can disconnect from this instance now:
```bash
exit
```

## Step 3: Delete Instance
```bash
gcloud compute instances delete quicksync 
```


## Step 4: Snapshot Disk

Create snapshot from that disk:
```bash
gcloud compute disks snapshot chaindata --zone=$ORIG_ZONE --snapshot-names=chaindata-snapshot 
```
* `ORIG_ZONE`: the zone where the original disk was created

## Step 5: Stamp out new disks in other regions

(Run this as many times as you need to populate all desired zones)  

```bash
gcloud compute disks create chaindata --type pd-ssd --source-snapshot=chaindata-snapshot --zone=$DEST_ZONE --kms-key=$KMS_KEY_NAME
```
* `DEST_ZONE`: the zone where you want to create the new disk.  This means you plan on running a validator/sentry in this zone.  
* `KMS_KEY_NAME`: the GCP KMS Key used to encrypt these disks.  While the original data on disk is public domain, these disks could potentially be hosting your node keys on them.  you might need to [create a kms key first.](./appendix-create-kms-key.md).  Once you have a kms key then set the KMS_KEY_NAME var (full uri). 

Note the selflink of this new disk, you'll need it in tfvars if you're using the terraform scripts:
```bash
gcloud compute disks describe chaindata --format=value"(selfLink)" --zone $DEST_ZONE
```

(Make sure you delete and recreate the original disk too)


