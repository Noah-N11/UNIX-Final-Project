# Create our custom VPC
resource "google_compute_network" "project_vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode             = "REGIONAL"
}

# Create our subnet
resource "google_compute_subnetwork" "project_subnet" {
  name          = var.subnet_name
  region        = var.region
  network       = google_compute_network.project_vpc.id
  ip_cidr_range = var.subnet_cidr

  private_ip_google_access = true
}

# Allow internal communication within our VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal-communication"
  network = google_compute_network.project_vpc.name

  direction = "INGRESS"

  source_ranges = [var.subnet_cidr]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }
}

# Allow SSH through Google Cloud IAP only
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-ssh-through-iap"
  network = google_compute_network.project_vpc.name

  direction = "INGRESS"

  source_ranges = ["35.235.240.0/20"]

  target_tags = ["allow-iap-ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Allow Google Cloud load balancer health checks
resource "google_compute_firewall" "allow_health_checks" {
  name    = "allow-load-balancer-health-checks"
  network = google_compute_network.project_vpc.name

  direction = "INGRESS"

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  target_tags = ["allow-health-checks"]

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "8000"]
  }
}