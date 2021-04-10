//name of the gcp project to use
variable "project_id" {
    type = string
}

//credentials for sa that will carry out all these operations
variable "sa_keyfile" {
    type = string
}

//a unique identifier prefixed to all resource names
variable "prefix" {
    type = string
}

//kms key for encrypting all disks
variable "kms_key" {
    type = string
}


variable "vpc_name" {
    type = string
    default = "terra"
}

variable "instance_type" {
    type = string
    default = "n2-standard-2"
}

variable "oracle_instance_type" {
    type = string
    default = "n2-standard-2"
}


//validator vars
variable "validator_region" {
    type = string
    default = "us-central1"
}
variable "validator_chaindisk" {
    type = string
}
variable "validator_network_name" {
    type = string
    default = "valnet"
}

//holly vars
variable "holly_region" {
    type = string
    default = "us-west1"
}
variable "holly_chaindisk" {
    type = string
}
variable "holly_network_name" {
    type = string
    default = "hollynet"
}

//shenzi vars
variable "shenzi_region" {
    type = string
    default = "us-east4"
}
variable "shenzi_chaindisk" {
    type = string
}
variable "shenzi_network_name" {
    type = string
    default = "shenzinet"
}





