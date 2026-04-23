provider "aws" {
  region  = "eu-north-1"
  profile = "default"
}
# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "lesson-5-terraform-state-bucket-1489"
  table_name  = "terraform-locks"
}

# # Підключаємо модуль VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  vpc_name           = "lesson-5-vpc"
  eks_cluster_name   = "eks-cluster-demo"
}
# Підключаємо модуль ECR
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-5-ecr"
  scan_on_push = true
}

module "eks" {
  source              = "./modules/eks"
  cluster_name        = "eks-cluster-demo"
  cluster_version     = "1.32"
  cluster_subnet_ids  = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  node_subnet_ids     = module.vpc.private_subnets
  node_group_name     = "general"
  node_instance_types = ["t3.small"]
  desired_size        = 1
  max_size            = 2
  min_size            = 1
}