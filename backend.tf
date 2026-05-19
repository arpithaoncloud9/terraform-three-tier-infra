# Remote backend for Terraform state
# Stores state in S3 with state locking via DynamoDB.
#
# Before running `terraform init`, you must create:
#   1. An S3 bucket (with versioning enabled) for state storage
#   2. A DynamoDB table with primary key "LockID" (String) for state locking
#
# Recommended one-time setup:
#   aws s3api create-bucket --bucket <your-bucket-name> --region us-east-1
#   aws s3api put-bucket-versioning --bucket <your-bucket-name> \
#     --versioning-configuration Status=Enabled
#   aws dynamodb create-table --table-name terraform-state-lock \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST
#
# Uncomment and update the values below to enable remote state.

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "aws-3tier-architecture/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }