# Create KMS Key

A Google Cloud KMS Key is a secure encyption key stored in your secure google keyring.  KMS Keys can be used for encrypting data at rest such as disks and secrets.  


## Create a Keyring
```bash
gcloud kms keyrings create $KEYRING_NAME --location global
```
* `KEYRING_NAME`: your choice

## Create a Key
```bash
gcloud kms keys create $KEY_NAME --keyring $KEYRING_NAME --location global --purpose encryption
KMS_KEY_NAME=$(gcloud kms keys describe $KEY_NAME --keyring $KEYRING_NAME --location global --format=value"(name)")
#you will need the value of KMS_KEY_NAME (full uri) anytime you want to use this key !
```
* `KEY_NAME`: your choice


