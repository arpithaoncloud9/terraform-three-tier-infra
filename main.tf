# =========================================================
# Root module - composes the four child modules.
# =========================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Kubernetes provider — authenticates via EKS cluster outputs
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}


# =========================================================
# VPC 
# =========================================================

module "vpc" {
  source = "./modules/vpc"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
}

# =========================================================
# alb
# =========================================================

module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

# =========================================================
# EKS — replaces compute module
# =========================================================

module "eks" {
  source = "./modules/eks"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  public_subnet_ids      = module.vpc.public_subnet_ids
  alb_security_group_id  = module.alb.alb_security_group_id
  node_instance_type     = var.node_instance_type
  node_desired_size      = var.node_desired_size
  node_min_size          = var.node_min_size
  node_max_size          = var.node_max_size
  db_password            = var.db_password
}

# =========================================================
# Register EKS nodes with ALB target group       
# =========================================================

resource "aws_autoscaling_attachment" "eks_to_alb" {
  autoscaling_group_name = module.eks.node_group_asg_name
  lb_target_group_arn    = module.alb.target_group_arn
}

# =========================================================
# WEEK 5: Compute module replaced by EKS in Week 6
# =========================================================

# module "compute" {
#   source = "./modules/compute"
#
#   project_name           = var.project_name
#   environment            = var.environment
#   vpc_id                 = module.vpc.vpc_id
#   private_app_subnet_ids = module.vpc.private_app_subnet_ids
#   alb_security_group_id  = module.alb.alb_security_group_id
#   target_group_arn       = module.alb.target_group_arn
#   instance_type          = var.instance_type
#   asg_min_size           = var.asg_min_size
#   asg_max_size           = var.asg_max_size
#   asg_desired_capacity   = var.asg_desired_capacity
#   db_password            = var.db_password
# }

# =========================================================
# Kubernetes Namespace — must exist before secret
# =========================================================

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = "aws-3tier-dev"
    labels = {
      project     = "aws-3tier"
      environment = "dev"
      managed-by  = "terraform"
    }
  }

  depends_on = [module.eks]
}

# =========================================================
# Kubernetes Secret — DB password injected securely into pods
# =========================================================

resource "kubernetes_secret_v1" "app_secrets" {
  metadata {
    name      = "aws-3tier-secrets"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  data = {
    db_password = var.db_password
  }

  depends_on = [module.eks]
}

# =========================================================
# database
# =========================================================

module "database" {
  source = "./modules/database"

  # ... existing lines ...


  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  private_db_subnet_ids   = module.vpc.private_db_subnet_ids
  app_security_group_id   = module.eks.eks_nodes_security_group_id
  db_engine               = var.db_engine
  db_engine_version       = var.db_engine_version
  db_instance_class       = var.db_instance_class
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
}

# =========================================================
# Add monitoring module
# =========================================================

module "monitoring" {
  source = "./modules/monitoring"

  project_name      = var.project_name
  environment       = var.environment
  ec2_role_name     = "aws-3tier-ec2-role"
  alert_email       = "arpithaoncloud9@gmail.com"
  alb_name          = "aws-3tier-alb"
  target_group_name = "aws-3tier-tg"
  asg_name          = module.eks.cluster_name
  rds_instance_id   = "aws-3tier-db"
}