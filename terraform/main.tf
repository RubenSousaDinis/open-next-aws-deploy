terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "aws-deploy-test-terraform-state"
    key    = "terraform.tfstate"
    region = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC for the database
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.app_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  tags = var.tags
}

# Security group for the database
resource "aws_security_group" "database" {
  name_prefix = "${var.app_name}-db-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Security group for Lambda functions
resource "aws_security_group" "lambda" {
  name_prefix = "${var.app_name}-lambda-"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Subnet group for RDS
resource "aws_db_subnet_group" "database" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = var.tags
}

# PostgreSQL RDS instance
resource "aws_db_instance" "database" {
  identifier = "${var.app_name}-db"

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.database.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = var.environment == "development"
  deletion_protection = var.environment == "production"

  tags = var.tags
}

# Parameter group for PostgreSQL
resource "aws_db_parameter_group" "database" {
  family = "postgres15"
  name   = "${var.app_name}-db-params"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = var.tags
}

# OpenNext module for Next.js deployment
module "open_next" {
  source  = "RJPearson94/open-next/aws//modules/tf-aws-open-next-zone"
  version = "3.1.0"

  prefix = "myapp-rubendinis-${random_id.suffix.hex}"
  folder_path = "../.open-next"

  # Server function configuration
  server_function = {
    handler = "index.handler"
    runtime = "nodejs20.x"
    environment_variables = {
      WLD_CLIENT_ID      = var.next_public_app_id
      NEXT_PUBLIC_APP_ID = var.next_public_app_id
      NODE_ENV           = "production"
      NEXTAUTH_SECRET    = var.nextauth_secret
      NEXTAUTH_URL       = "https://drrlmb6jtrdvb.cloudfront.net"
      DATABASE_URL       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.database.endpoint}/${var.db_name}"
    }
  }

  # Provider configurations
  providers = {
    aws.server_function = aws
    aws.iam            = aws
    aws.dns            = aws
    aws.global         = aws
  }
}

resource "random_id" "suffix" {
  byte_length = 4
} 