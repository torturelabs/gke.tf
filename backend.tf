terraform {
  backend "gcs" {
    credentials = "credentials.json"
    bucket      = "terraform-state-d9644d283ab84d9caa0afe660e070831"
    prefix      = "dev"
  }
}
