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

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    dnf update -y
    dnf install -y httpd
    systemctl enable httpd
    systemctl start httpd

    # IMDSv2: request a token first, then use it for every metadata call
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/instance-id)

    AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/placement/availability-zone)

    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>3-Tier AWS Architecture — Maria</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          margin: 0;
          padding: 0;
          background: linear-gradient(135deg, #1e3a8a 0%, #5b21b6 100%);
          color: #fff;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .container {
          max-width: 720px;
          padding: 3rem 2rem;
          text-align: center;
        }
        h1 {
          font-size: 2.5rem;
          margin: 0 0 0.5rem;
          letter-spacing: -0.02em;
        }
        .subtitle {
          font-size: 1.1rem;
          opacity: 0.85;
          margin: 0 0 2rem;
        }
        .card {
          background: rgba(255, 255, 255, 0.1);
          backdrop-filter: blur(10px);
          border: 1px solid rgba(255, 255, 255, 0.2);
          border-radius: 12px;
          padding: 1.5rem;
          margin: 1.5rem 0;
          font-family: "SF Mono", Menlo, monospace;
          font-size: 0.95rem;
        }
        .card-label {
          opacity: 0.7;
          font-size: 0.75rem;
          text-transform: uppercase;
          letter-spacing: 0.1em;
          margin-bottom: 0.5rem;
        }
        .card-value {
          font-size: 1.1rem;
          font-weight: 600;
        }
        .footer {
          margin-top: 2rem;
          font-size: 0.85rem;
          opacity: 0.7;
        }
        a {
          color: #fff;
          text-decoration: underline;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>3-Tier AWS Architecture</h1>
        <p class="subtitle">Built by Maria · Provisioned with Terraform</p>

        <div class="card">
          <div class="card-label">Served by EC2 instance</div>
          <div class="card-value">$INSTANCE_ID</div>
        </div>

        <div class="card">
          <div class="card-label">Availability Zone</div>
          <div class="card-value">$AZ</div>
        </div>

        <p class="footer">
          Refresh this page to see traffic balanced across two AZs.<br>
          Code: <a href="https://github.com/arpithaoncloud9/terraform-three-tier-infra">github.com/arpithaoncloud9</a>
        </p>
      </div>
    </body>
    </html>
    HTML
  EOF
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.environment}-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(local.user_data)

  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
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
  health_check_grace_period = 60

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