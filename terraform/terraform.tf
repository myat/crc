# Terraform config

terraform {

  backend "s3" {
    key = "global/crc-front/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.59.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.3.0"
    }
    gandi = {
      source  = "go-gandi/gandi"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.4"
}
