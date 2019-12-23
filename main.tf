// Provides access to available Google Container Engine versions in a zone for a given project.
// https://www.terraform.io/docs/providers/google/d/google_container_engine_versions.html
data "google_container_engine_versions" "on-prem" {
  location = var.zone
  project  = var.project
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
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
    // don't expose cluster nodes to Internet
    // use Cloud NAT or proxy host to get access to outside
    enable_private_nodes = true

    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr
  }

  // disable built-in logging and monitoring
  // will set up our own
  logging_service    = "none"
  monitoring_service = "none"

  // Here we use gcloud to gather authentication information about our new cluster and write that
  // information to kubectls config file
  provisioner "local-exec" {
    command = <<EOF
      set -e
      gcloud container clusters get-credentials ${google_container_cluster.primary.name} \
        --zone ${google_container_cluster.primary.location} --project ${var.project} &&
      kubectl create clusterrolebinding creator-cluster-admin \
        --clusterrole cluster-admin --user $(gcloud config get-value account) \
        --username admin --password ${random_password.password.result}
EOF
  }

  // Deal with basic GKE rights to be cluster admin in k8s
  master_auth {
    username = "admin"
    password = random_password.password.result
  }
}

variable "node_scopes" {
  type        = list
  description = "Access scopes"
  default = [
    // Stackdriver Logging API, Write Only
    "https://www.googleapis.com/auth/logging.write",
    // Stackdriver Monitoring API, Full
    "https://www.googleapis.com/auth/monitoring",
    // Storage, Read Write
    // Needed for images access for GCR
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/devstorage.read_write",
  ]
}

// Separate node pool for persistent workloads
resource "google_container_node_pool" "primary_persistent_nodes" {
  name       = "persistent-pool"
  location   = var.zone
  node_count = 1
  cluster    = google_container_cluster.primary.name
  project    = var.project

  node_config {
    machine_type = var.instance_type
    oauth_scopes = var.node_scopes
  }

  autoscaling {
    min_node_count = 0
    max_node_count = 3
  }
}

// Separate node pool for preemtible workloads
resource "google_container_node_pool" "primary_preemtible_nodes" {
  name     = "preemtible-pool"
  location = var.zone
  cluster  = google_container_cluster.primary.name
  project  = var.project

  node_config {
    preemptible = true

    labels = {
      preemptible = "true"
      dedicated   = "preemptible-worker-pool"
    }

    // by default don't run workloads on that node type
    taint = [
      {
        key    = "dedicated"
        value  = "preemptible-worker-pool"
        effect = "NO_SCHEDULE"
      }
    ]

    machine_type = var.instance_type
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
