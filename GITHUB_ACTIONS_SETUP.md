# GitHub Actions CI/CD Setup

This guide explains how to set up the GitHub Actions workflow for automatic deployment to AWS.

## Overview

The workflow will:
1. **Test** - Run linting and type checking on every push and PR
2. **Deploy** - Deploy infrastructure and application with Terraform (using OpenNext module) when code is pushed to the main branch

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository:

### AWS Credentials
- `AWS_ACCESS_KEY_ID` - Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret access key

### Application Secrets
- `WLD_CLIENT_ID` - Worldcoin client ID
- `NEXT_PUBLIC_APP_ID` - Your Next.js public app ID
- `NEXTAUTH_SECRET` - NextAuth.js secret key
- `NEXTAUTH_URL` - Your application URL (e.g., https://your-domain.com)
- `DB_PASSWORD` - Database password for Terraform deployment

## How to Set Up Secrets

1. Go to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret** for each secret above
5. Enter the secret name and value
6. Click **Add secret**

## AWS IAM Permissions

Your AWS user needs the following permissions for Terraform deployment:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:*",
                "s3:*",
                "lambda:*",
                "apigateway:*",
                "iam:*",
                "logs:*",
                "cloudwatch:*",
                "route53:*",
                "cloudfront:*",
                "acm:*",
                "ssm:*",
                "secretsmanager:*",
                "rds:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "route53:*",
                "acm:*",
                "cloudfront:*"
            ],
            "Resource": "*"
        }
    ]
}
```

## Workflow Triggers

- **Push to main branch**: Triggers test and deploy
- **Pull Request to main**: Triggers only test (no deployment)

## Deployment Process

1. **Test Job**:
   - Installs dependencies
   - Runs ESLint
   - Runs TypeScript type checking

2. **Deploy Job** (only on main branch push):
   - Sets up AWS credentials
   - Installs Terraform
   - Generates Prisma client
   - Builds Next.js app with OpenNext
   - Deploys infrastructure and application with Terraform (VPC, RDS, OpenNext, etc.)
   - Posts deployment URL as a comment

## Troubleshooting

### Common Issues

1. **AWS Credentials Error**: Make sure your AWS access keys are correct and have the necessary permissions
2. **Build Failures**: Check that all dependencies are properly installed and the build script works locally
3. **SST Deployment Errors**: Verify that your SST configuration is correct and all required environment variables are set

### Debugging

- Check the GitHub Actions logs for detailed error messages
- Test the deployment locally first using `sst deploy --stage production`
- Verify that all secrets are properly configured

## Local Testing

Before pushing to trigger the workflow, test locally:

```bash
# Install dependencies
npm ci

# Run tests
npm run lint
npx tsc --noEmit

# Test build
npm run build:open-next

# Test Terraform deployment
cd terraform
terraform init
terraform plan -var="environment=production"

# Test Terraform deployment
cd terraform
terraform init
terraform plan -var="environment=production"
```

## Security Notes

- Never commit secrets to your repository
- Use GitHub's built-in secret management
- Regularly rotate your AWS access keys
- Consider using AWS IAM roles for more secure deployments 