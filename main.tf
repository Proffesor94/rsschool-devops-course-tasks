terraform {
  backend "s3" {
    bucket = "terraform-states-bucket01"
    key    = "terraform.tfstate"
    region = "eu-north-1"
  }
}
