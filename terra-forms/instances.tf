resource "google_service_account" "val_service_account" {
  account_id   = "validator"
  display_name = "Val Service Account"
}

resource "google_service_account" "sentry_service_account" {
  account_id   = "sentry"
  display_name = "Sentry Service Account"
}

resource "google_service_account" "oracle_service_account" {
  account_id   = "oracle"
  display_name = "Oracle Service Account"
}


//validator vm
resource "google_compute_instance" "validator" {
  name         = "${var.prefix}-validator"
  machine_type = var.instance_type
  zone         = "${var.validator_region}-a"

  tags = ["validator"]

  boot_disk {
    initialize_params {
      image = "rhel-cloud/rhel-7"
    }
    kms_key_self_link = var.kms_key
  }

  attached_disk {
    source = var.validator_chaindisk
    kms_key_self_link = var.kms_key
  }
  
  network_interface {
    subnetwork = var.validator_network_name
  }

  service_account {
    email  = google_service_account.val_service_account.email
    scopes = ["cloud-platform"]
    //https://cloud.google.com/sdk/gcloud/reference/alpha/compute/instances/set-scopes#--scopes
  }
}

//holly vm
resource "google_compute_instance" "holly" {
  name         = "${var.prefix}-holly"
  machine_type = var.instance_type
  zone         = "${var.holly_region}-a"

  tags = ["sentry"]

  boot_disk {
    initialize_params {
      image = "rhel-cloud/rhel-7"
    }
    kms_key_self_link = var.kms_key
  }

  attached_disk {
    source = var.holly_chaindisk
    kms_key_self_link = var.kms_key
  }
  
  network_interface {
    subnetwork = var.holly_network_name
    access_config {}
  }

  service_account {
    email  = google_service_account.sentry_service_account.email
    scopes = ["cloud-platform"]
  }
}

//shenzi vm
resource "google_compute_instance" "shenzi" {
  name         = "${var.prefix}-shenzi"
  machine_type = var.instance_type
  zone         = "${var.shenzi_region}-a"

  tags = ["sentry"]

  boot_disk {
    initialize_params {
      image = "rhel-cloud/rhel-7"
    }
    kms_key_self_link = var.kms_key
  }

  attached_disk {
    source = var.shenzi_chaindisk
    kms_key_self_link = var.kms_key
  }

 // metadata = {
   // ssh-keys = "jo:${file("~/.ssh/id_rsa.pub")}"
  //}
  
  network_interface {
    subnetwork = var.shenzi_network_name
    access_config {}
  }

  service_account {
    email  = google_service_account.sentry_service_account.email
    scopes = ["cloud-platform"]
  }
}


//oracle vm
resource "google_compute_instance" "oracle" {
  name         = "${var.prefix}-oracle"
  machine_type = var.oracle_instance_type
  zone         = "${var.shenzi_region}-a"

  tags = ["oracle"]

  boot_disk {
    initialize_params {
      image = "rhel-cloud/rhel-7"
    }
    kms_key_self_link = var.kms_key
  }
  
  network_interface {
    subnetwork = var.shenzi_network_name
    access_config {}
  }

  service_account {
    email  = google_service_account.oracle_service_account.email
    scopes = ["cloud-platform"]
  }
}