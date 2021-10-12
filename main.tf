terraform {
}

provider "aws" {
  region  = var.region
  profile = "AWSAdministratorAccess-661199018908"
}

resource "aws_ecr_repository" "lynx-fh" {
  name                 = "lynx-fh"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "vpc" {
  source             = "./vpc"
  name               = var.name
  environment        = var.environment
  cidr               = var.cidr
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  private_subnets_db = var.private_subnets_db
  availability_zones = var.availability_zones
}

module "eks" {
  source          = "./eks"
  name            = var.name
  environment     = var.environment
  region          = var.region
  k8s_version     = var.k8s_version
  vpc_id          = module.vpc.id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  kubeconfig_path = var.kubeconfig_path
}

module "ingress" {
  source       = "./ingress"
  name         = var.name
  environment  = var.environment
  region       = var.region
  vpc_id       = module.vpc.id
  cluster_id   = module.eks.cluster_id
}


module "data" {
  source       		= "./data"
  name         		= var.name
  environment  		= var.environment
  vpc_id       		= module.vpc.id
  cidr               = var.cidr
  private_subnets = module.vpc.private_subnets_db
  public_subnets = module.vpc.public_subnets
  availability_zones = var.availability_zones
  data_username  = var.data_username
  data_password  = var.data_password
}
