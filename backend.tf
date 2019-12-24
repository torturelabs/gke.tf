terraform {
  backend "gcs" {
    bucket      = "terraform-state-d9644d283ab84d9caa0afe660e070831"
    prefix      = "dev"
  }
}
