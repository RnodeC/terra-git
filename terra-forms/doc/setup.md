# Terraform Setup

These are the things you'll need to do on your client before you can use this terraform.  First of all, you'll need a Google Cloud Project.  


## And install terraform
```bash
wget https://releases.hashicorp.com/terraform/0.14.9/terraform_0.14.9_linux_amd64.zip -O tf.zip
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
SA_NAME=terra-tf

gcloud iam service-accounts keys create ${PRIVATE_DIR}/gcp-sa.json --iam-account terra-tf@${PROJECT_ID}.iam.gserviceaccount.com
```
* `PRIVATE_DIR`: local dir you want to store this very important secret
* `PROJECT_ID`: your gcp project id

## Create encryption keys
This is a secure encyption key stored in a google keyring
```bash
gcloud kms keyrings create $KEYRING_NAME --location global
KEYRING=$(gcloud kms keyrings describe $KEYRING_NAME --location global --format=value"(name)")
gcloud kms keys create $KEY_NAME --keyring $KEYRING --location global
gcloud kms keys list --keyring $KEYRING --location global 
#note the full key name!
```
* `KEYRING_NAME`: your choice
* `KEY_NAME`: your choice




## Upload secrets to Google Secret Manager 
```bash
#oracle config file containing your api key
SECRET_NAME=oracle-config
SA_NAME=oracle
gcloud secrets create $SECRET_NAME --replication-policy="automatic" --kms-key-name=$KMS_KEY_NAME
gcloud secrets versions add $SECRET_NAME --data-file=${PRIVATE_DIR}/oracle-default.js

#validator signing key
SECRET_NAME=validator
SA_NAME=validator
gcloud secrets create $SECRET_NAME --replication-policy="automatic" --kms-key-name=$KMS_KEY_NAME
gcloud secrets versions add $SECRET_NAME --data-file=${PRIVATE_DIR}/priv_validator_key.json

#validator id key
SECRET_NAME=node
SA_NAME=node
gcloud secrets create $SECRET_NAME --replication-policy="automatic" --kms-key-name=$KMS_KEY_NAME
gcloud secrets versions add $SECRET_NAME --data-file=${PRIVATE_DIR}/node_key.json
```
* `PRIVATE_DIR`: local dir you want to store this very important secret
* `PROJECT_ID`: your gcp project id
* `KMS_KEY_NAME`: the key name you *noted* in previous step


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
Note - these IAM bindings (not to mention the secrets themselves) should be created in terraform, but it does not really seem possible based on doc I am seeing.... https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam
```bash
#oracle api
SECRET_NAME=oracle-config
SA_NAME=oracle
gcloud secrets add-iam-policy-binding $SECRET_NAME \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

#val key
SECRET_NAME=validator
SA_NAME=validator
gcloud secrets add-iam-policy-binding $SECRET_NAME \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

#node key
SECRET_NAME=node
SA_NAME=validator
gcloud secrets add-iam-policy-binding $SECRET_NAME \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```