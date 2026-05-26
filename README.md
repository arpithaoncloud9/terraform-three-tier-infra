# terraform-three-tier-infra

# WEEK 1
Production-style 3-tier AWS architecture provisioned end-to-end with Terraform — VPC, ALB, Auto Scaling Group, and RDS — using a modular, real-world layout.

![Architecture diagram](docs/architecture.svg)

---

## Overview

This project provisions a classic **3-tier architecture** on AWS:

- **Web tier** — public Application Load Balancer (ALB) accepting HTTP traffic
- **App tier** — EC2 Auto Scaling Group in private subnets, only reachable through the ALB
- **Database tier** — RDS instance in isolated private subnets, only reachable from the app tier

Everything is deployed across **two Availability Zones** for high availability and provisioned as code with Terraform.

---

## Tech Stack

| Layer            | Service / Tool                                  |
| ---------------- | ----------------------------------------------- |
| IaC              | Terraform >= 1.5, AWS Provider ~> 5.0           |
| Networking       | VPC, public + private subnets, IGW, NAT Gateway |
| Web tier         | Application Load Balancer                       |
| App tier         | EC2, Launch Template, Auto Scaling Group        |
| Database tier    | RDS MySQL 8.0                                   |
| State management | S3 + DynamoDB (remote backend)                  |
| CI               | GitHub Actions (fmt / validate / plan)          |

---

## Features

- **High availability** across two Availability Zones for every tier
- **Strict network segmentation** with separate public, app, and DB subnets
- **Defense in depth** using security groups that reference each other rather than CIDR blocks
- **No public IPs** on app or DB instances — outbound internet only via NAT Gateway
- **Auto Scaling Group** with Launch Template and **IMDSv2 enforced**
- **Automatic instance refresh** on Launch Template changes
- **Encryption at rest** for RDS storage
- **Resource tagging** via provider `default_tags` + per-resource tags

---

## Architecture & Design Decisions

### Why a 3-tier design?
The 3-tier pattern cleanly separates concerns: the web tier terminates public traffic, the app tier runs business logic in a security boundary, and the database tier is isolated even further. This enforces defense in depth at the network layer.

### Why one NAT Gateway instead of two?
To save cost (~$32/month per NAT). The trade-off: if AZ-A goes down, instances in AZ-B lose outbound internet. Production should run one NAT per AZ.

### Why Launch Template instead of Launch Configuration?
Launch Configurations are deprecated. Launch Templates support IMDSv2 enforcement and mixed instance types — the only forward-compatible choice.

### Why security-group-to-security-group references?
App SG references ALB SG; DB SG references App SG. Tighter, scales without rewriting CIDR lists, and survives subnet changes.

### Why parameterize `multi_az` and `backup_retention_period`?
The same Terraform code runs in dev (single-AZ, no backups) and production (Multi-AZ, 7-day backups) by flipping two variables. This is exactly how production teams parameterize environment-specific settings.

### Why automatic instance refresh on Launch Template changes?
By default, Terraform updates the Launch Template version but doesn't replace running instances — they keep serving the old user_data. Adding `instance_refresh` with `triggers = ["launch_template"]` rolls instances automatically on every apply.

---

## Deploy

```bash
# 1. Configure
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars (set db_username and db_password)

# 2. Provision
make init
make fmt
make validate
make plan
make apply

# 3. Test
curl $(terraform output -raw alb_dns_name)

# 4. Destroy when done
make destroy
```

---

# Live Deployment

The infrastructure was deployed end-to-end and validated before being destroyed to control costs.

## Terraform apply Output:

![Terraform apply](docs/screenshots/08_terraform-apply-successful.png)

## Network Layer: 

### VPC Resource Map

![VPC resource map](docs/screenshots/01_vpc-resource-map.png)

## Security Boundaries:

### Security Groups 

![Security groups](docs/screenshots/02_security_groups.png)

## Web Layer:

### ALB DNS

![ALB DNS](docs/screenshots/05_alb-DNS.png)

### Load balancing across instances 

**az-1a and az-1b**

![Load balancing across instances](docs/screenshots/07_alb-load-distribution-1a-1b.png)

## Compute Layer:

### ASG Capacity

![Auto Scaling Group](docs/screenshots/06_asg-capacity.png)

### EC2 Instances Across AZs

![EC2 instances across AZs](docs/screenshots/03_ec2_instances.png)

### Registered Healthy Targets

![Target group health](docs/screenshots/04_target-group-health.png)

## Database tier:

### DB Instance 

![RDS instance](docs/screenshots/09_rds-instance.png)

---

## Cost Estimate

For a single `dev` deployment in `us-east-1` left running continuously:

| Resource                         | Approx. monthly cost |
| -------------------------------- | -------------------- |
| 2 × t3.micro EC2 (ASG)           | ~$15                 |
| Application Load Balancer        | ~$22                 |
| NAT Gateway                      | ~$32                 |
| RDS db.t3.micro (single-AZ)      | ~$15                 |
| **Total (idle)**                 | **~$85 / month**     |

Always run `make destroy` between test sessions.

---

## What I Learned

- **Module boundaries matter.** Picking what goes in `vpc/` vs `alb/` vs `compute/` is the difference between reusable code and tangled code.
- **Security group references over CIDR blocks** is a small decision that quietly makes infrastructure much safer and easier to evolve.
- **IMDSv2 enforcement catches subtle bugs.** When I enforced IMDSv2 on the Launch Template, my initial user_data (using IMDSv1 curl calls) silently failed to fetch instance metadata — taught me to validate user_data assumptions against the metadata service version in use.
- **Launch Template updates don't auto-refresh ASG instances.** Adding `instance_refresh` with `triggers = ["launch_template"]` is the production-grade way to handle this — Terraform now rolls instances on every Launch Template change.
- **Free Plan constraints can push code in the right direction.** Parameterizing Multi-AZ and backup retention was forced by the Free Plan but ended up being a more flexible design than hardcoding production-only values.

---

## License

MIT


# WEEK 2 - Remote State Management

Terraform state is stored remotely in S3 with DynamoDB locking to support
team collaboration and prevent state corruption.

## Why Remote State?

By default, Terraform stores state locally in `terraform.tfstate`. This works
for solo projects but breaks immediately in a team or CI environment — two
engineers running `apply` simultaneously will corrupt each other's state.

This project uses:
- **S3** as the single source of truth for state storage (with versioning, so
  every change is recoverable)
- **DynamoDB** for state locking — prevents concurrent applies from running at
  the same time

## Bootstrap (One-Time Manual Setup)

The S3 bucket and DynamoDB table cannot be managed by Terraform itself
(chicken-and-egg problem). Create them once manually before running
`terraform init`:

```bash
# Create S3 bucket

aws s3api create-bucket \
  --bucket <your-bucket-name> \
  --region us-east-1

# Enable versioning

aws s3api put-bucket-versioning \
  --bucket <your-bucket-name> \
  --versioning-configuration Status=Enabled

# Block public access

aws s3api put-public-access-block \
  --bucket <your-bucket-name> \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB lock table

aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Activate the Backend

Update `backend.tf` with your bucket name, then run:

```bash
terraform init -migrate-state
```

Terraform will prompt you to confirm the migration. Type `yes`. After this,
state lives in S3 — your local `terraform.tfstate` is no longer the source
of truth.

## Backend Configuration

See [`backend.tf`](./backend.tf) for the full configuration.

```hcl
terraform {
  backend "s3" {
    bucket         = "your-bucket-name"
    key            = "aws-3tier-architecture/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

## Verification

After running `terraform init -migrate-state`, verify the state file landed
in S3:

```bash
aws s3 ls s3://<your-bucket-name>/aws-3tier-architecture/
```

You should see `terraform.tfstate` listed. Run `terraform plan` to confirm
state integrity — output should reflect your current infrastructure with no
unexpected changes.

## Screenshots

| Resource | Details |
|----------|---------|
| ![S3 bucket](docs/screenshots/s3-bucket.png) | State bucket in us-east-1 with versioning enabled |
| ![DynamoDB lock table](docs/screenshots/dynamodb-lock-table.png) | `terraform-state-lock` table — Active, LockID partition key |
| ![terraform init -migrate-state](docs/screenshots/backend-migration.png) | Backend migration — `Successfully configured the backend 's3'`|
| ![State file in S3](docs/screenshots/s3-state-file.png) | `terraform.tfstate` stored under `aws-3tier-architecture/` |

