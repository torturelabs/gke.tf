// Identifies allowable version range for Terraform Google Provider
provider "google" {
  //version = "~> 3.0.0"
  //uncomment after 3 version will be graduated from beta

  credentials = file("credentials.json")
}

provider "google-beta" {
  // same
  credentials = file("credentials.json")
}
