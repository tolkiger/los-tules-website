#!/bin/bash
set -e

echo "=========================================="
echo "Los Tules Website - Migration to Shared Constructs"
echo "Phase 2: Deploy Without Custom Domain"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "infra/app.py" ]; then
    echo -e "${RED}Error: Must run from los-tules-website directory${NC}"
    exit 1
fi

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    echo "Run: aws configure"
    exit 1
fi
echo -e "${GREEN}✓ AWS credentials configured${NC}"
echo ""

# Check if site is built
if [ ! -d "site/out" ] || [ -z "$(ls -A site/out)" ]; then
    echo -e "${YELLOW}Building Next.js site...${NC}"
    cd site
    npm ci
    npm run build
    cd ..
    echo -e "${GREEN}✓ Site built${NC}"
else
    echo -e "${GREEN}✓ Site already built (site/out/ exists)${NC}"
fi
echo ""

# Check if menu PDF exists
if [ ! -f "infra/los-tules-menu2026.pdf" ]; then
    echo -e "${RED}Warning: Menu PDF not found at infra/los-tules-menu2026.pdf${NC}"
    echo "The deployment will continue but menu PDF won't be uploaded."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ Menu PDF found${NC}"
fi
echo ""

# Install shared-website-constructs locally
echo -e "${YELLOW}Installing shared-website-constructs...${NC}"
cd ../../website-infrastructure/shared-website-constructs
pip install -e . > /dev/null 2>&1
cd ../../websites/los-tules-website
echo -e "${GREEN}✓ Shared constructs installed${NC}"
echo ""

# Set environment variables for deployment WITHOUT custom domain
echo -e "${YELLOW}Setting environment variables (no custom domain)...${NC}"
export SITE_NAME="los-tules-website"
export DOMAIN_NAME=""  # Empty = no custom domain
export HOSTED_ZONE_ID=""
export HOSTED_ZONE_NAME=""
export MENU_PDF_ENABLED="true"
export MENU_PDF_BUCKET_NAME="los-tules-menu-files"
export MENU_PDF_FILENAME="los-tules-menu2026.pdf"
echo -e "${GREEN}✓ Environment variables set${NC}"
echo ""

# Install CDK dependencies
echo -e "${YELLOW}Installing CDK dependencies...${NC}"
cd infra
pip install -r requirements.txt > /dev/null 2>&1
echo -e "${GREEN}✓ CDK dependencies installed${NC}"
echo ""

# Show the diff
echo -e "${YELLOW}=========================================="
echo "CDK Diff - Preview of Changes"
echo "==========================================${NC}"
echo ""
echo "This shows what will change in your AWS stack."
echo "Review carefully before proceeding."
echo ""
cdk diff
echo ""

# Ask for confirmation
echo -e "${YELLOW}=========================================="
echo "Ready to Deploy"
echo "==========================================${NC}"
echo ""
echo "This will:"
echo "  1. Update the existing LosTulesWebsiteStack"
echo "  2. Migrate to shared-website-constructs"
echo "  3. Keep the same CloudFront distribution"
echo "  4. Keep the same S3 buckets"
echo "  5. Deploy WITHOUT custom domain (CloudFront default URL)"
echo ""
read -p "Proceed with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi
echo ""

# Deploy
echo -e "${YELLOW}Deploying stack...${NC}"
cdk deploy --require-approval never

echo ""
echo -e "${GREEN}=========================================="
echo "✓ Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Check the CloudFront URL in the outputs above"
echo "  2. Visit the website and verify it works"
echo "  3. Check the menu PDF URL and verify it's accessible"
echo "  4. Test all website features"
echo ""
echo "After verification, we'll set up the custom domain (lostuleskc.com)"
echo ""
