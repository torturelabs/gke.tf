// Provides access to available Google Container Engine versions in a zone for a given project.
// https://www.terraform.io/docs/providers/google/d/google_container_engine_versions.html
data "google_container_engine_versions" "on-prem" {
  location = var.zone
  project  = var.project
}

// https://www.terraform.io/docs/providers/google/d/google_container_cluster.html
// Create the primary cluster for this project.

// Create the GKE Cluster
resource "google_container_cluster" "primary" {
  provider = google-beta
  name     = "demo-space"
  location = var.zone

  // node count in each AZ
  initial_node_count = 1

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true

  // use latest supported K8s version
  // don't use that in prod
  min_master_version = data.google_container_engine_versions.on-prem.latest_master_version

  project = var.project

  ip_allocation_policy {
  }

  private_cluster_config {
    // don't expose cluster nodes to Interner
    enable_private_nodes = true

    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr
  }

  // Here we use gcloud to gather authentication information about our new cluster and write that
  // information to kubectls config file
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${var.project}"
  }
}

variable "node_scopes" {
  type = list
  default = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      // the nodes in the cluster can acquire the permission to pull the image
      // from GCR
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_write",
    ]
}

// Separate node pool for persistent workloads
resource "google_container_node_pool" "primary_persistent_nodes" {
  name       = "persistent-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1
  project    = var.project

  node_config {
    machine_type = "n1-standard-1"
    oauth_scopes = var.node_scopes
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
}

// Separate node pool for preemtible workloads
resource "google_container_node_pool" "primary_preemtible_nodes" {
  name       = "preemtible-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1
  project    = var.project

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"
    oauth_scopes = var.node_scopes
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
}

output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "primary_zone" {
  value = google_container_cluster.primary.location
}
