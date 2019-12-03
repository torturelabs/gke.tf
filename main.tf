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

  // autoscaling stuff
  // https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-provisioning
  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      maximum       = 10
    }
    resource_limits {
      resource_type = "memory"
      maximum       = 96
    }
  }

  // use latest supported K8s version
  // don't use that in prod
  min_master_version = data.google_container_engine_versions.on-prem.latest_master_version

  project = var.project

  // Here we use gcloud to gather authentication information about our new cluster and write that
  // information to kubectls config file
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${var.project}"
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

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "primary_zone" {
  value = google_container_cluster.primary.location
}
