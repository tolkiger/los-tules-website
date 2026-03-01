# Los Tules Website - Deployment Instructions

## Current Status

✅ **Preparation Complete** - Ready to deploy!

The website has been migrated to use the `shared-website-constructs` library. All code changes are ready, and we're deploying **without a custom domain** first to verify everything works.

## What's Changed

### Before (Old Stack):
- Custom CDK code in `infra/stacks/infra_stack.py`
- ~150 lines of infrastructure code
- Manual CloudFront, S3, ACM configuration

### After (New Stack):
- Thin wrapper in `infra/app.py` (~50 lines)
- Uses `shared-website-constructs` library
- Same functionality, cleaner code
- CI/CD ready with `buildspec.yml`

## Deployment Steps (TODAY)

### Step 1: Verify Prerequisites

Make sure you have:
- [ ] AWS credentials configured (`aws sts get-caller-identity` works)
- [ ] Node.js installed (`node --version`)
- [ ] Python 3.12+ installed (`python3 --version`)
- [ ] AWS CDK installed (`cdk --version`)
- [ ] Site built (`site/out/` directory exists with files)
- [ ] Menu PDF at `infra/los-tules-menu2026.pdf`

### Step 2: Run the Migration Script

```bash
cd websites/los-tules-website
./migrate-to-shared-constructs.sh
```

**What the script does:**
1. Checks AWS credentials
2. Builds the Next.js site (if needed)
3. Installs shared-website-constructs locally
4. Sets environment variables (no domain)
5. Shows `cdk diff` (preview of changes)
6. Asks for confirmation
7. Runs `cdk deploy`

### Step 3: Review the Diff

The script will show you what CDK plans to change. Look for:
- ✅ **Update** operations (good - modifying existing resources)
- ⚠️ **Replace** operations (review carefully - recreating resources)
- ❌ **Delete** operations (should be minimal)

**Expected changes:**
- CloudFront distribution: UPDATE (not replace)
- S3 buckets: UPDATE (not replace)
- IAM roles: UPDATE or CREATE
- Lambda functions: CREATE (for S3 deployment)

### Step 4: Confirm and Deploy

When prompted, type `y` to proceed. The deployment will take 5-10 minutes.

### Step 5: Verify the Website

After deployment, CDK will output:
```
Outputs:
LosTulesWebsiteStack.WebsiteURL = https://d1234567890abc.cloudfront.net
LosTulesWebsiteStack.MenuPDFURL = https://los-tules-menu-files.s3.amazonaws.com/los-tules-menu2026.pdf
LosTulesWebsiteStack.CloudFrontDistributionID = E1234567890ABC
```

**Test checklist:**
- [ ] Visit the WebsiteURL - site loads correctly
- [ ] Check all images load
- [ ] Test navigation (scroll, click buttons)
- [ ] Click "View Our Menu" - PDF opens
- [ ] Test on mobile (responsive design)
- [ ] Check browser console for errors

## If Something Goes Wrong

### Rollback Plan

If the deployment fails or the site doesn't work:

```bash
# 1. Go back to the old code
git checkout main

# 2. Redeploy the old stack
cd infra
source .venv/bin/activate  # or create new venv
pip install -r requirements.txt
cdk deploy

# 3. Website returns to previous state
```

### Common Issues

**Issue: "Module not found: shared_website_constructs"**
```bash
# Install the shared construct locally
cd ../../website-infrastructure/shared-website-constructs
pip install -e .
cd ../../websites/los-tules-website
```

**Issue: "site/out/ directory not found"**
```bash
# Build the Next.js site
cd site
npm ci
npm run build
cd ..
```

**Issue: "AWS credentials not configured"**
```bash
aws configure
# Enter your access key, secret key, region (us-east-1)
```

**Issue: "CDK bootstrap required"**
```bash
cdk bootstrap aws://YOUR_ACCOUNT_ID/us-east-1
```

## After Successful Deployment

### Next Steps:

1. **Verify everything works** ✅
2. **Review DOMAIN_MANAGEMENT_PLAN.md** for adding custom domain
3. **Set up Route 53 hosted zone** for lostuleskc.com
4. **Add custom domain** in follow-up deployment
5. **Set up CI/CD pipeline** in pipeline-factory

### Adding the Custom Domain (Later)

After DNS is configured:

```bash
# Set environment variables with domain
export DOMAIN_NAME="lostuleskc.com"
export HOSTED_ZONE_ID="Z1234567890ABC"
export HOSTED_ZONE_NAME="lostuleskc.com"

# Redeploy
cd infra
cdk deploy
```

CDK will:
- Create ACM certificate
- Add custom domain to CloudFront
- Create Route 53 A-record
- Website accessible at lostuleskc.com

## Documentation

- **MIGRATION_PLAN.md** - Overall migration strategy
- **DOMAIN_MANAGEMENT_PLAN.md** - Detailed plan for Route 53 + GoDaddy
- **README.md** - Original deployment guide (will be updated)

## Support

If you encounter issues:
1. Check the error message carefully
2. Review the "Common Issues" section above
3. Check AWS CloudFormation console for stack events
4. Review CloudWatch logs for Lambda functions

## Summary

**Today's Goal:** Deploy Los Tules with shared-website-constructs (no domain)

**Success Criteria:**
- ✅ Website loads at CloudFront URL
- ✅ Menu PDF is accessible
- ✅ All features work correctly
- ✅ No errors in browser console

**After Success:**
- Review domain management plan
- Set up Route 53 hosted zone
- Add custom domain in follow-up deployment
- Set up CI/CD pipeline

---

**Ready to deploy?** Run `./migrate-to-shared-constructs.sh` and let's verify the migration works!
