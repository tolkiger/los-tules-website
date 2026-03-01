# Migration Plan: Los Tules Website to Shared Constructs

## Current State
- Live website deployed with stack name: `LosTulesWebsiteStack`
- Custom CDK code in `infra/stacks/infra_stack.py`
- Menu PDF bucket: `los-tules-menu-files`
- Menu PDF file: `los-tules-menu2026.pdf`
- No custom domain (uses CloudFront default)
- CloudFront OAI for S3 access

## Target State
- Same stack name: `LosTulesWebsiteStack` (to avoid recreation)
- Thin `infra/app.py` using `shared-website-constructs`
- Custom domain: `lostuleskc.com`
- Route 53 hosted zone for domain
- ACM certificate for HTTPS
- Same menu PDF functionality
- buildspec.yml for CI/CD integration

## Migration Steps

### Phase 1: Preparation (No AWS Changes) ✅ COMPLETE
1. ✅ Create GitHub repository
2. ✅ Create issue #1
3. ✅ Create feature branch
4. ✅ Update app.py to use shared-website-constructs
5. ✅ Update requirements.txt
6. ✅ Create buildspec.yml
7. ✅ Document migration plan (this file)

### Phase 2: Deploy Without Custom Domain (TODAY)
1. Install shared-website-constructs locally
2. Set environment variables (no domain)
3. Run `cdk diff` to preview changes
4. Run `cdk deploy` to migrate stack
5. Verify website works at CloudFront URL
6. Verify menu PDF is accessible
7. Test all website features

### Phase 3: Domain Setup (LATER - After Phase 2 Success)
1. Create domain-management CDK app
2. Create Route 53 hosted zone for `lostuleskc.com`
3. Optionally: Add GoDaddy API integration
4. Deploy domain-management stack
5. Update GoDaddy nameservers (manual or automated)
6. Wait for DNS propagation

### Phase 4: Add Custom Domain (AFTER DNS Propagation)
1. Set environment variables with domain info
2. Run `cdk diff` to preview domain addition
3. Run `cdk deploy` to add ACM certificate and custom domain
4. Verify website works at lostuleskc.com
5. Update pipeline-factory config

### Phase 5: Cleanup
1. Remove old `infra/stacks/` directory
2. Update README with new structure
3. Commit and push changes
4. Create PR and merge

## Risk Mitigation

### Why This Is Safe:
- Same stack name = CDK recognizes existing resources
- Shared construct creates resources with compatible logical IDs
- CloudFront distribution will be updated, not replaced
- S3 buckets will be updated, not replaced
- Menu PDF bucket name stays the same: `los-tules-menu-files`

### What Could Go Wrong:
- If logical IDs don't match, CDK might try to replace resources
- CloudFront updates can take 15-30 minutes
- Domain DNS propagation takes time

### Rollback Plan:
If something goes wrong:
1. `git checkout main` (revert to old code)
2. `cd infra && cdk deploy` (redeploy old stack)
3. Website returns to previous state

## Environment Variables Needed

### For Today's Deployment (No Custom Domain):
```bash
export SITE_NAME="los-tules-website"
export DOMAIN_NAME=""  # Empty = no custom domain
export HOSTED_ZONE_ID=""
export HOSTED_ZONE_NAME=""
export MENU_PDF_ENABLED="true"
export MENU_PDF_BUCKET_NAME="los-tules-menu-files"
export MENU_PDF_FILENAME="los-tules-menu2026.pdf"
```

### For Later (After DNS Setup):
```bash
export SITE_NAME="los-tules-website"
export DOMAIN_NAME="lostuleskc.com"
export HOSTED_ZONE_ID="Z<your-zone-id>"
export HOSTED_ZONE_NAME="lostuleskc.com"
export MENU_PDF_ENABLED="true"
export MENU_PDF_BUCKET_NAME="los-tules-menu-files"
export MENU_PDF_FILENAME="los-tules-menu2026.pdf"
```

For pipeline (in websites.json):
```json
{
  "siteName": "los-tules-website",
  "githubRepo": "los-tules-website",
  "domainName": "lostuleskc.com",
  "hostedZoneId": "Z<your-zone-id>",
  "hostedZoneName": "lostuleskc.com",
  "menuPdfEnabled": true,
  "menuPdfBucketName": "los-tules-menu-files",
  "menuPdfFilename": "los-tules-menu2026.pdf"
}
```

## Testing Checklist

Before declaring success:
- [ ] Website loads at CloudFront URL
- [ ] Website loads at lostuleskc.com (after DNS propagation)
- [ ] HTTPS works (green padlock)
- [ ] Menu PDF accessible at public URL
- [ ] All images load correctly
- [ ] Navigation works
- [ ] Mobile responsive
- [ ] CloudFront cache invalidation works

## Next Steps

1. **YOU NEED TO**: Set up Route 53 hosted zone for `lostuleskc.com`
2. **YOU NEED TO**: Provide AWS credentials for deployment
3. **I WILL**: Test the migration with `cdk diff` first
4. **I WILL**: Deploy with `cdk deploy` after you approve the diff
5. **WE WILL**: Verify the website is live and working
6. **LATER**: Add logo after migration is complete
