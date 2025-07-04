# Deployment Guide

This guide will help you deploy your Next.js application to AWS using OpenNext and Terraform.

## Prerequisites

1. **AWS CLI** - Install and configure with your AWS credentials
   ```bash
   # Install AWS CLI
   brew install awscli  # macOS
   
   # Configure AWS credentials
   aws configure
   ```

2. **Terraform** - Install Terraform
   ```bash
   # Install Terraform
   brew install terraform  # macOS
   ```

3. **Node.js** - Make sure you have Node.js installed (version 18+ recommended)

## Quick Deployment

The easiest way to deploy is using the provided deployment script:

```bash
./deploy.sh
```

This script will:
1. Build your Next.js application
2. Build with OpenNext
3. Initialize Terraform
4. Deploy to AWS

## Manual Deployment

If you prefer to deploy manually, follow these steps:

### 1. Build the Application

```bash
# Install dependencies
npm install

# Build Next.js
npm run build

# Build with OpenNext
npm run build:open-next
```

### 2. Configure Terraform

Edit `terraform.tfvars` to customize your deployment:

```hcl
# AWS Configuration
aws_region = "us-east-1"  # Change to your preferred region
app_name   = "your-app-name"

# Optional: Custom domain
# domain_name = "your-app.example.com"
# hosted_zone = "example.com"

# Environment variables
environment_variables = {
  NODE_ENV = "production"
  # Add other environment variables your app needs
}
```

### 3. Deploy with Terraform

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the deployment
terraform apply

# Or use the helper script
./run.sh init
./run.sh plan
./run.sh apply
```

## Configuration Options

### Custom Domain

To use a custom domain, uncomment and configure these variables in `terraform.tfvars`:

```hcl
domain_name = "your-app.example.com"
hosted_zone = "example.com"
```

Make sure your domain is managed by Route53 in the same AWS account.

### Environment Variables

Add environment variables your application needs in `terraform.tfvars`:

```hcl
environment_variables = {
  NODE_ENV = "production"
  DATABASE_URL = "your-database-url"
  API_KEY = "your-api-key"
}
```

### AWS Region

Change the AWS region in `terraform.tfvars`:

```hcl
aws_region = "us-west-2"  # or any other AWS region
```

## What Gets Deployed

The Terraform configuration creates:

- **S3 Bucket** - Stores static assets
- **CloudFront Distribution** - CDN for global content delivery
- **Lambda Function** - Handles server-side rendering
- **API Gateway** - REST API for Lambda function
- **PostgreSQL RDS Database** - Managed database for your application
- **VPC** - Virtual private cloud for secure networking
- **Security Groups** - Network security for database and Lambda
- **Route53** (optional) - DNS management for custom domains
- **IAM Roles** - Security permissions

## Useful Commands

```bash
# Navigate to terraform directory
cd terraform

# View deployment outputs
terraform output

# Destroy the deployment
terraform destroy

# View CloudFront distribution
terraform output cloudfront_domain_name

# View Lambda function
terraform output lambda_function_name

# View database endpoint
terraform output database_endpoint

# View database name
terraform output database_name

# Or use the helper script
./run.sh output
./run.sh destroy
```

## Database Setup

After deployment, you need to set up the database schema:

### Option 1: Using the initialization script
```bash
# Run the database initialization script
node scripts/init-db.js
```

### Option 2: Manual setup
```bash
# Generate Prisma client
npm run db:generate

# Push schema to database
npm run db:push
```

### Option 3: Using Prisma Studio (for development)
```bash
# Open Prisma Studio to manage your database
npm run db:studio
```

## Troubleshooting

### Common Issues

1. **AWS Credentials Not Configured**
   ```bash
   aws configure
   ```

2. **Terraform Not Installed**
   ```bash
   brew install terraform
   ```

3. **Build Failures**
   - Check that all dependencies are installed: `npm install`
   - Verify Next.js configuration in `next.config.ts`

4. **Permission Errors**
   - Ensure your AWS user has the necessary permissions for:
     - S3
     - CloudFront
     - Lambda
     - API Gateway
     - RDS (for database)
     - VPC (for networking)
     - IAM
     - Route53 (if using custom domain)

5. **Database Connection Issues**
   - Verify the database endpoint is correct: `cd terraform && terraform output database_endpoint`
   - Check that the database password is set in `terraform/terraform.tfvars`
   - Ensure the Lambda function has VPC access to the database
   - Test database connectivity: `npm run db:studio`

### Getting Help

- [OpenNext Documentation](https://open-next.js.org/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)

## Cost Optimization

The deployment uses:
- **S3** - Pay per storage and requests
- **CloudFront** - Pay per data transfer
- **Lambda** - Pay per request and execution time
- **API Gateway** - Pay per request
- **RDS PostgreSQL** - Pay per instance hour and storage
- **VPC** - Free tier eligible, minimal costs for NAT Gateway

For development/testing, consider using a different AWS region or destroying resources when not in use:

```bash
cd terraform
terraform destroy

# Or use the helper script
./run.sh destroy
``` 