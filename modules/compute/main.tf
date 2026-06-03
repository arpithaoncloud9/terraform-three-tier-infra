# =========================================================
# Compute Module - Launch Template + Auto Scaling Group
# =========================================================

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# SSH Key Pair

resource "tls_private_key" "app_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "app_key" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = tls_private_key.app_key.public_key_openssh

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-key"
  })
}

resource "local_file" "app_key" {
  filename        = "${path.module}/${var.project_name}-${var.environment}-key.pem"
  content         = tls_private_key.app_key.private_key_pem
  file_permission = "0400"
}


data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Allow HTTP from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "All egress (for NAT-routed outbound traffic)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-sg"
  })
}

# IAM role for EC2 to pull from ECR
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecr_pull" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    dnf update -y

    # Install Docker
    dnf install -y docker
    systemctl enable docker
    systemctl start docker

    # Install AWS CLI v2
    dnf install -y aws-cli

    # IMDSv2 token for metadata
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/instance-id)

    AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/placement/availability-zone)

    # Log into ECR using instance IAM role
    aws ecr get-login-password --region us-east-1 | \
      docker login --username AWS --password-stdin \
      120300897885.dkr.ecr.us-east-1.amazonaws.com

    # Pull image from ECR
    docker pull 120300897885.dkr.ecr.us-east-1.amazonaws.com/aws-3tier-app:latest

    # Run the container
    docker run -d \
      --name app \
      --restart always \
      -p 80:3000 \
      -e INSTANCE_ID=$INSTANCE_ID \
      -e AZ=$AZ \
      120300897885.dkr.ecr.us-east-1.amazonaws.com/aws-3tier-app:latest
  EOF
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.environment}-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  key_name = aws_key_pair.app_key.key_name

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(local.user_data)

  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${var.project_name}-${var.environment}-app"
      Tier = "app"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-${var.environment}-asg"
  desired_capacity          = var.asg_desired_capacity
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  vpc_zone_identifier       = var.private_app_subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300 # Changed from 60 to 300 seconds

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # NEW: automatically roll instances when the launch template changes
  
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 60
    }

  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}