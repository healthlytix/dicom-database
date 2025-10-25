terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.84.0"
    }
  }
  required_version = ">= 1.10"
}

provider "aws" {
  region = "us-west-1"
  default_tags {
    tags = {
      Environment = var.provider_tags.environment
      Owner       = var.provider_tags.owner
      Application = "Orthanc"
    }
  }
}

provider "tls" {}