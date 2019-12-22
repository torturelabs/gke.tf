resource "google_compute_router" "router" {
  name    = "gcp-${var.zone}-cloud-router"
  region  = var.zone
  network = "default"
  project = var.project
}

resource "google_compute_router_nat" "cloud_nat" {
  name   = "gcp-${var.zone}-nat-1"
  router = google_compute_router.router.name
  region = google_compute_router.router.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project
}
