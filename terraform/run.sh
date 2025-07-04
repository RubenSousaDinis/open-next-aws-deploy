#!/bin/bash

set -e

# Function to show usage
show_usage() {
    echo "Usage: $0 [init|plan|apply|destroy|output]"
    echo ""
    echo "Commands:"
    echo "  init     - Initialize Terraform"
    echo "  plan     - Plan the deployment"
    echo "  apply    - Apply the deployment"
    echo "  destroy  - Destroy the deployment"
    echo "  output   - Show outputs"
    echo ""
    echo "Examples:"
    echo "  $0 init"
    echo "  $0 plan"
    echo "  $0 apply"
    echo "  $0 output"
}

# Check if command is provided
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "init")
        echo "🏗️  Initializing Terraform..."
        terraform init
        ;;
    "plan")
        echo "📋 Planning Terraform deployment..."
        terraform plan
        ;;
    "apply")
        echo "🚀 Deploying to AWS..."
        terraform apply -auto-approve
        ;;
    "destroy")
        echo "🗑️  Destroying deployment..."
        terraform destroy -auto-approve
        ;;
    "output")
        echo "📊 Terraform outputs:"
        terraform output
        ;;
    *)
        echo "❌ Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac 