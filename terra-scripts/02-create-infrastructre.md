# Terraform Setup

`terraform` (not to be confused with Terraform Labs) is a great way to manage infrastructure on the cloud. 

These are the things you'll need to do on your client before you can use this terraform.  First of all, you'll need a Google Cloud Project.  


## And install terraform cli
```bash
wget https://releases.hashicorp.com/terraform/0.14.9/terraform_0.14.9_linux_amd64.zip -O tf.zip #double check url to get latest version
unzip tf.zip
rm -f tf.zip
sudo mv terraform /usr/local/bin
```

## Create GCP Service Account for terraform access
We will name this account `terra-tf`, feel free to modify of course
```bash
gcloud iam service-accounts create terra-tf \
    --description "this is a service account" \
    --display-name terra-tf 
```

## Apply necessary roles to this Service Account
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:terra-tf@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/compute.networkAdmin
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:terra-tf@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/compute.securityAdmin
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:terra-tf@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/compute.instanceAdmin
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:terra-tf@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/iam.serviceAccountCreator
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:terra-tf@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/iam.serviceAccountDeleter
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:terra-tf@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/iam.serviceAccountUser
```
* `PROJECT_ID`: your gcp project id

> https://cloud.google.com/compute/docs/access/iam#iam_with_service_accounts

## Obtain Keyfile for this Service Account

```bash
gcloud iam service-accounts keys create ${PRIVATE_DIR}/gcp-sa.json --iam-account terra-tf@${PROJECT_ID}.iam.gserviceaccount.com
```
* `PRIVATE_DIR`: local dir you want to store this very important secret
* `PROJECT_ID`: your gcp project id



## Upload secrets to Google Secret Manager 

*If this is your first time using Secret Manager and KMS Keys, you will need to go through these instructions: https://cloud.google.com/secret-manager/docs/cmek*  

This is the full [`default.js`](https://github.com/terra-project/oracle-feeder/blob/main/price-server/config/default-sample.js) config file you'll use for your price-server.  It contains your api key.  
```bash
gcloud secrets create $SECRET_NAME --replication-policy="automatic" --kms-key-name=$KMS_KEY_NAME
gcloud secrets versions add $SECRET_NAME --data-file=${PRIVATE_DIR}/oracle-default.js
```
* `SECRET_NAME`: your choice
* `PRIVATE_DIR`: local dir you want to store this very important secret
* `KMS_KEY_NAME`: the GCP KMS Key used to encrypt these secrets.  Encrypting these secrets with your own key will add just another layer of protection.  You might need to [create a kms key first.](./appendix-create-kms-key.md).  Once you have a kms key then set the KMS_KEY_NAME var (full uri). 

Validator signing key (`priv_validator_key.json`). If this is your first time setting up your architecture, then you won't have these values yet.  But if you are creating a new environment with new keys then maybe you want to do this.   
```bash
gcloud secrets create $SECRET_NAME --replication-policy="automatic" --kms-key-name=$KMS_KEY_NAME
gcloud secrets versions add $SECRET_NAME --data-file=${PRIVATE_DIR}/priv_validator_key.json
```
* `SECRET_NAME`: your choice
* `PRIVATE_DIR`: local dir you want to store this very important secret
* `KMS_KEY_NAME`: the GCP KMS Key used to encrypt these secrets.  Encrypting these secrets with your own key will add just another layer of protection.  You might need to [create a kms key first.](./appendix-create-kms-key.md).  Once you have a kms key then set the KMS_KEY_NAME var (full uri). 

Validator id key (`node_key.json`).  If this is your first time setting up your architecture, then you won't have these values yet.  But if you are creating a new environment with new keys then maybe you want to do this.  
```bash 
gcloud secrets create $SECRET_NAME --replication-policy="automatic" --kms-key-name=$KMS_KEY_NAME
gcloud secrets versions add $SECRET_NAME --data-file=${PRIVATE_DIR}/node_key.json
```
* `SECRET_NAME`: your choice
* `PRIVATE_DIR`: local dir you want to store this very important secret
* `KMS_KEY_NAME`: the GCP KMS Key used to encrypt these secrets.  Encrypting these secrets with your own key will add just another layer of protection.  You might need to [create a kms key first.](./appendix-create-kms-key.md).  Once you have a kms key then set the KMS_KEY_NAME var (full uri). 


## Setup terraform.tfvars file
```bash
project_id = ""
sa_keyfile = ""
prefix = ""
kms_key = ""
validator_chaindisk = ""
holly_chaindisk = ""
shenzi_chaindisk = ""
```

## Run terraform
```bash
terraform apply -auto-approve
```


## Apply necessary IAM permissions to the created service accounts
Note - these IAM bindings should be created in terraform, but it does not really seem possible based on doc I am seeing.... https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam

Oracle config file (with your api key):
```bash
SA_NAME=oracle
gcloud secrets add-iam-policy-binding $SECRET_NAME \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```
* `SECRET_NAME`: whatever you named this earlier (`gcloud kms keys list....`)

Validator Key (if necessary)
```bash
SA_NAME=validator
gcloud secrets add-iam-policy-binding $SECRET_NAME \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```
* `SECRET_NAME`: whatever you named this earlier (`gcloud kms keys list....`)

Node Key (if necessary)
```bash
SA_NAME=validator
gcloud secrets add-iam-policy-binding $SECRET_NAME \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```
* `SECRET_NAME`: whatever you named this earlier (`gcloud kms keys list....`)
