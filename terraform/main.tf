terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.58.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      managed_by = "terraform"
      Project    = "PB UNICESUMAR"
      CostCenter = "C092000024"
    }
  }
}

# FALTA O BACKEND DO S3 

terraform {
  backend "s3" {
    bucket = "remote-state-project-docker-pb"
    region = "us-east-1"
    key    = "web-auto/terraform.tfstate"
  }
}