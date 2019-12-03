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
  name               = "demo-space"
  location           = var.zone

  // node count in each AZ
  initial_node_count = 1

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

output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "primary_zone" {
  value = google_container_cluster.primary.location
}
