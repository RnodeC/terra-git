
//validator network
module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 3.0"

    project_id   = var.project_id
    network_name = "${var.prefix}-${var.vpc_name}"
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           =  var.validator_network_name
            subnet_ip             = "192.168.1.0/29"
            subnet_region         = var.validator_region
            subnet_private_access = "true"
        },
        {
            subnet_name           = var.holly_network_name
            subnet_ip             = "192.168.1.8/29"
            subnet_region         = var.holly_region
            subnet_private_access = "true"
        },
        {
            subnet_name           = var.shenzi_network_name
            subnet_ip             = "192.168.1.16/29"
            subnet_region         = var.shenzi_region
            subnet_private_access = "true"
        }
    ]
}

// router and nat for validator to reach internet
resource "google_compute_router" "router" {
  name    = "val-router"
  region  = var.validator_region
  network = module.vpc.network_name

  bgp {
    asn = 64514
  }
}

// router and nat for validator to reach internet
resource "google_compute_router_nat" "nat" {
  name                               = "val-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name = var.validator_network_name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = false
    filter = "ERRORS_ONLY"
  }
}



resource "google_compute_firewall" "allow-ssh-from-iap" {
  network = module.vpc.network_name


  name           = "allow-ssh-from-iap"
  description    = "allow jeff to ssh in to any node via the IAP"
  target_tags    = ["sentry", "validator", "oracle"]
  source_ranges  = ["35.235.240.0/20"]
  priority       = 0
  
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
}

resource "google_compute_firewall" "allow-sentries-to-validator" {
  network = module.vpc.network_name

  name           = "allow-sentries-to-validator"
  description    = "allow all sentries to reach validator ports 26656 and 26657 (rpc)"
  target_tags    = ["validator"]
  source_tags    = ["sentry"]
  priority       = 1

  allow {
    protocol = "tcp"
    ports    = ["26656","26657"]
  }
}


resource "google_compute_firewall" "allow-internet-to-sentries" {
  network = module.vpc.network_name

  name          = "allow-internet-to-sentries"
  description   = "allow internet to reach all sentries on port 26656 and 26657"
  target_tags   = ["sentry"]
  source_ranges = ["0.0.0.0/0"]
  priority      = 2
  
  allow {
    protocol = "tcp"
    ports    = ["26656","26657"]
  }
}


resource "google_compute_firewall" "allow-oracle-to-validator" {
  network = module.vpc.network_name

  name           = "allow-oracle-to-validator"
  description    = "allow oracle to reach validator port 1317 (lcd)"
  target_tags    = ["validator"]
  source_tags    = ["oracle"]
  priority       = 3

  allow {
    protocol = "tcp"
    ports    = ["1317"]
  }
}

resource "google_compute_firewall" "allow-egress" {
    network = module.vpc.network_name

    name           = "allow-egress"
    description    = "allow all nodes to reach internet"
    destination_ranges  = ["0.0.0.0/0"]
    direction = "EGRESS"
    priority       = 4
    
    allow {
      protocol = "tcp"
    }
}

resource "google_compute_firewall" "deny-all-other" {
    network = module.vpc.network_name

    name           = "deny-all-other"
    description    = "block all non-terra related traffic everywhere"
    source_ranges  = ["0.0.0.0/0"]
    priority       = 10
    
    deny {
      protocol = "tcp"
    }

    deny {
      protocol = "udp"
    }
}



