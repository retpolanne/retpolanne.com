terraform {
  backend "s3" {
    endpoint = "nyc3.digitaloceanspaces.com"
    bucket = "terraform-state-backend-bucket"
    region = "us-west-1"
    key = "terraform.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check = true
  }
}
