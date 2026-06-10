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

module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "compute" {
  source = "./modules/compute"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  alb_security_group_id  = module.alb.alb_security_group_id
  target_group_arn       = module.alb.target_group_arn
  instance_type          = var.instance_type
  asg_min_size           = var.asg_min_size
  asg_max_size           = var.asg_max_size
  asg_desired_capacity   = var.asg_desired_capacity

}

module "database" {
  source = "./modules/database"

  # ... existing lines ...


  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  private_db_subnet_ids   = module.vpc.private_db_subnet_ids
  app_security_group_id   = module.compute.app_security_group_id
  db_engine               = var.db_engine
  db_engine_version       = var.db_engine_version
  db_instance_class       = var.db_instance_class
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
}

# Add monitoring module
module "monitoring" {
  source = "./modules/monitoring"

  project_name       = var.project_name
  environment        = var.environment
  ec2_role_name      = module.compute.ec2_role_name
  alert_email        = "your-email@example.com"  # ← CHANGE THIS to your email
  alb_name           = module.alb.alb_name
  target_group_name  = module.alb.target_group_name
  asg_name           = module.compute.asg_name
  rds_instance_id    = module.database.rds_instance_id
}