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

# 1. Networking Infrastructure (VPC, Subnets, NAT, IGW)
module "networking" {
  source   = "./modules/networking"
  vpc_cidr = "10.0.0.0/16"
}

# 2. Backend Infrastructure (ECS, ECR, ALB, Security Groups)
module "backend_ecs" {
  source             = "./modules/backend_ecs"
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnets
  private_subnet_ids = module.networking.private_subnets
  app_port           = var.app_port
  mongo_uri          = var.mongo_uri
}