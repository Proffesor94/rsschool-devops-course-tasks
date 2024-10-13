terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68"
    }
  }

  backend "s3" {
    bucket  = "terraform-states-bucket01"
    key     = "state/terraform.tfstate"
    region  = "eu-north-1"
    encrypt = true
  }
}