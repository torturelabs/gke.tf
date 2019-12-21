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

variable "instance_type" {
  description = "Type for node instances to use (both persistent and preemtible)"
  type = string
  default = "n1-standard-1"
}
