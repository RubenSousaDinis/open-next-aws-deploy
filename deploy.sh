#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting deployment..."

# Check if required tools are installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials are not configured. Please run 'aws configure' first."
    exit 1
fi

echo "📦 Building Next.js application..."
npm run build

echo "🔧 Building OpenNext bundle..."
npm run build:open-next

echo "🔗 Creating symlink for Terraform compatibility..."
cd .open-next
# Remove old symlink if it exists
rm -f server-function
# Create symlink from server-function to server-functions/default
ln -s server-functions/default server-function
cd ..

echo "🔧 Initializing Terraform..."
cd terraform
terraform init

echo "📋 Planning Terraform deployment..."
terraform plan

echo "🚀 Applying Terraform configuration..."
terraform apply -auto-approve

echo "✅ Deployment completed!"

echo ""
echo "🌐 Your application is now available at:"
# Extract CloudFront URL from terraform output
APP_URL=$(terraform output open_next_outputs | grep 'cloudfront_url' | sed 's/.*"cloudfront_url" = "\([^"]*\)".*/\1/')
echo "$APP_URL"

echo ""
echo "📊 Other useful outputs:"
terraform output