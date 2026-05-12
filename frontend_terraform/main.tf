terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "frontend_cdn" {
  source   = "./modules/frontend_cdn"
  app_name = var.app_name
}