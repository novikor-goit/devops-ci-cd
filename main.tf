provider "aws" {
  region  = "eu-north-1"
  profile = "default"
}

data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
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
  node_instance_types = ["t3.medium"]
  desired_size        = 2
  max_size            = 2
  min_size            = 1
}

module "jenkins" {
  source    = "./modules/jenkins"
  namespace = "jenkins"

  admin_user     = "admin"
  admin_password = var.jenkins_admin_password

  depends_on = [module.eks]
}

module "argo_cd" {
  source    = "./modules/argo_cd"
  namespace = "argocd"

  depends_on = [module.eks]
}

module "rds" {
  source = "./modules/rds"

  name                       = "myapp-db"
  use_aurora                 = true
  aurora_instance_count      = 2

  # --- Aurora-only ---
  engine_cluster                = "aurora-mysql"
  engine_version_cluster        = "8.0.mysql_aurora.3.04.0"
  parameter_group_family_aurora = "aurora-mysql8.0"

  # --- RDS-only ---
  engine                     = "mysql"
  engine_version             = "8.0"
  parameter_group_family_rds = "mysql8.0"

  # Common
  instance_class             = "db.t3.medium"
  allocated_storage          = 20
  db_name                    = "myapp"
  username                   = "admin"
  password                   = var.db_password
  subnet_private_ids         = module.vpc.private_subnets
  subnet_public_ids          = module.vpc.public_subnets
  publicly_accessible        = true
  vpc_id                     = module.vpc.vpc_id
  multi_az                   = true
  backup_retention_period    = 7
  parameters = {
    max_connections                 = "200"
    log_bin_trust_function_creators = "1"
  }

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}

