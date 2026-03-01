---
inclusion: manual
---

# CI/CD Pipeline for Los Tules Website

This steering file contains instructions for setting up and using the CI/CD pipeline for automatic deployments.

## Overview

The project includes GitHub Actions workflows that automatically deploy the website when code is pushed to the main branch. This eliminates the need to manually run `./deploy.sh`.

## Workflow Files

- `.github/workflows/deploy.yml` - Main deployment pipeline (auto-deploys on push to main)
- `.github/workflows/deploy-preview.yml` - Preview builds only (no deployment)

## Setup Requirements

1. GitHub repository with code pushed
2. AWS credentials added as GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. Repository must have Actions enabled

## Deployment Process

The pipeline automatically:
1. Checks out code
2. Installs Node.js and Python
3. Installs dependencies
4. Builds Next.js site (`npm run build`)
5. Installs CDK dependencies
6. Configures AWS credentials
7. Bootstraps CDK (if needed)
8. Deploys to AWS (`cdk deploy`)

## Usage

### Automatic Deployment
```bash
git add .
git commit -m "Updated content"
git push
# Deployment happens automatically in 5-10 minutes
```

### Manual Trigger
1. Go to GitHub repository → Actions tab
2. Select "Deploy Los Tules Website"
3. Click "Run workflow"
4. Select "main" branch
5. Click "Run workflow" button

## Monitoring

- Check deployment status: GitHub repository → Actions tab
- View logs: Click on any workflow run
- Get deployment URL: Check workflow output logs

## Rollback

```bash
git log --oneline              # Find commit to rollback to
git revert <commit-hash>       # Revert to previous version
git push                       # Auto-deploys old version
```

## Cost

- GitHub Actions: Free (2,000 minutes/month for private repos)
- Each deployment: ~8 minutes
- Monthly capacity: ~250 deployments
- AWS costs: Same as manual deployment (~$1/month)

## Troubleshooting

### Deployment Fails
1. Check GitHub Actions logs for specific error
2. Verify AWS credentials in GitHub Secrets
3. Ensure CDK is bootstrapped: `cd infra && cdk bootstrap`
4. Test build locally: `cd site && npm run build`

### AWS Credentials Error
- Secret names must be exactly: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- No extra spaces or characters
- Credentials must have CDK deployment permissions

### Build Errors
- Check syntax errors in code
- Test locally before pushing
- Review GitHub Actions logs for specific error messages

## Documentation Files

Reference documentation (for user setup):
- `docs/CICD_SETUP_GUIDE.md` - Detailed setup instructions
- `docs/CICD_CHECKLIST.md` - Step-by-step checklist
- `docs/CICD_DIAGRAM.md` - Visual flow diagrams
- `docs/QUICK_REFERENCE.md` - Common commands

## When to Use

Use CI/CD when:
- Making frequent updates to the website
- Working with multiple team members
- Want automatic deployments
- Need deployment history and rollback capability

Continue using manual deployment (`./deploy.sh`) when:
- Making one-off changes
- Testing infrastructure changes
- CI/CD is not yet set up
- Prefer manual control over deployments
