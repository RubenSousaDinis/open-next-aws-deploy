#!/bin/bash

# Script to set up S3 backend for Terraform state management
# This creates the S3 bucket and enables versioning for state files

set -e

BUCKET_NAME="aws-deploy-test-terraform-state"
REGION="eu-west-1"

echo "🚀 Setting up Terraform S3 backend..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials are not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI and credentials are configured"

# Create S3 bucket if it doesn't exist
echo "📦 Creating S3 bucket: $BUCKET_NAME"
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "ℹ️  Bucket $BUCKET_NAME already exists"
else
    # eu-west-1 needs LocationConstraint
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
    echo "✅ Bucket $BUCKET_NAME created successfully"
fi

# Enable versioning on the bucket
echo "🔄 Enabling versioning on bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "🔐 Enabling server-side encryption..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Block public access
echo "🚫 Blocking public access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "✅ S3 backend setup completed!"
echo ""
echo "📝 Next steps:"
echo "1. Run 'terraform init' in the terraform directory"
echo "2. Terraform will now use S3 to store state"
echo "3. Your deployments will be incremental and won't recreate resources unnecessarily" 