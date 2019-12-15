variable "zone" {
  description = "The zone in which to create the Kubernetes cluster. Must match the region"
  type        = string
}

variable "project" {
  description = "the project for this network"
  type        = string
}

variable "master_ipv4_cidr" {
  description = "IP range for cluster masters"
  type = string
}
