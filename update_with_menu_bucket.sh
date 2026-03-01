#!/bin/bash
set -e

echo "============================================"
echo "  Los Tules - Adding Menu PDF S3 Bucket"
echo "============================================"
echo ""

# Define paths
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$PROJECT_ROOT/site"
INFRA_DIR="$PROJECT_ROOT/infra"
CDK_STACK_FILE="$INFRA_DIR/infra_stack.py"
PAGE_FILE="$SITE_DIR/app/page.tsx"
MENU_PDF="$INFRA_DIR/los-tules-menu2026.pdf"

# ============================================
# Step 0: Verify menu PDF exists
# ============================================
echo "Step 0: Checking for menu PDF file..."
if [ ! -f "$MENU_PDF" ]; then
    echo ""
    echo "ERROR: Menu PDF not found!"
    echo "Expected location: $MENU_PDF"
    echo ""
    echo "Please place 'los-tules-menu2026.pdf' in the infra/ directory and run this script again."
    exit 1
fi
echo "  Found: $MENU_PDF"
echo ""

# ============================================
# Step 1: Update CDK Stack
# ============================================
echo "Step 1: Updating CDK stack with menu PDF bucket..."

cat > "$CDK_STACK_FILE" << 'CDKSTACK'
from aws_cdk import (
    Stack,
    RemovalPolicy,
    CfnOutput,
    aws_s3 as s3,
    aws_s3_deployment as s3deploy,
    aws_cloudfront as cloudfront,
    aws_cloudfront_origins as origins,
    aws_iam as iam,
)
from constructs import Construct
import os


class InfraStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # ========================================
        # Website S3 Bucket
        # ========================================
        website_bucket = s3.Bucket(
            self,
            "LosTulesWebsiteBucket",
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
        )

        # ========================================
        # CloudFront OAI
        # ========================================
        oai = cloudfront.OriginAccessIdentity(
            self,
            "LosTulesOAI",
            comment="OAI for Los Tules website",
        )

        website_bucket.grant_read(oai)

        # ========================================
        # CloudFront Distribution
        # ========================================
        distribution = cloudfront.Distribution(
            self,
            "LosTulesDistribution",
            default_behavior=cloudfront.BehaviorOptions(
                origin=origins.S3Origin(
                    website_bucket,
                    origin_access_identity=oai,
                ),
                viewer_protocol_policy=cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
            ),
            default_root_object="index.html",
            error_responses=[
                cloudfront.ErrorResponse(
                    http_status=403,
                    response_http_status=200,
                    response_page_path="/index.html",
                ),
                cloudfront.ErrorResponse(
                    http_status=404,
                    response_http_status=200,
                    response_page_path="/index.html",
                ),
            ],
        )

        # ========================================
        # Deploy website files to S3
        # ========================================
        site_out_dir = os.path.join(os.path.dirname(__file__), "..", "..", "site", "out")

        s3deploy.BucketDeployment(
            self,
            "LosTulesWebsiteDeployment",
            sources=[s3deploy.Source.asset(site_out_dir)],
            destination_bucket=website_bucket,
            distribution=distribution,
            distribution_paths=["/*"],
        )

        # ========================================
        # Menu PDF S3 Bucket (NEW)
        # ========================================
        menu_bucket = s3.Bucket(
            self,
            "LosTulesMenuBucket",
            bucket_name="los-tules-menu-files",
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
            block_public_access=s3.BlockPublicAccess(
                block_public_acls=False,
                block_public_policy=False,
                ignore_public_acls=False,
                restrict_public_buckets=False,
            ),
            object_ownership=s3.ObjectOwnership.BUCKET_OWNER_PREFERRED,
        )

        # Add public read policy to menu bucket
        menu_bucket.add_to_resource_policy(
            iam.PolicyStatement(
                actions=["s3:GetObject"],
                resources=[menu_bucket.arn_for_objects("*")],
                principals=[iam.AnyPrincipal()],
            )
        )

        # ========================================
        # Deploy menu PDF to menu bucket (NEW)
        # ========================================
        menu_pdf_dir = os.path.join(os.path.dirname(__file__), "..")

        s3deploy.BucketDeployment(
            self,
            "LosTulesMenuDeployment",
            sources=[s3deploy.Source.asset(
                menu_pdf_dir,
                exclude=["*", "!los-tules-menu2026.pdf"],
            )],
            destination_bucket=menu_bucket,
            content_type="application/pdf",
        )

        # ========================================
        # Outputs
        # ========================================
        CfnOutput(
            self,
            "WebsiteURL",
            value=f"https://{distribution.distribution_domain_name}",
            description="Los Tules Website URL",
        )

        CfnOutput(
            self,
            "MenuPDFURL",
            value=f"https://{menu_bucket.bucket_regional_domain_name}/los-tules-menu2026.pdf",
            description="Los Tules Menu PDF URL",
        )

        CfnOutput(
            self,
            "CloudFrontDistributionID",
            value=distribution.distribution_id,
            description="CloudFront Distribution ID",
        )

        CfnOutput(
            self,
            "WebsiteBucketName",
            value=website_bucket.bucket_name,
            description="Website S3 Bucket Name",
        )

        CfnOutput(
            self,
            "MenuBucketName",
            value=menu_bucket.bucket_name,
            description="Menu PDF S3 Bucket Name",
        )
CDKSTACK

echo "  CDK stack updated successfully."
echo ""

# ============================================
# Step 2: Update page.tsx with menu PDF URL
# ============================================
echo "Step 2: Updating page.tsx with menu PDF URL..."

if grep -q "your-s3-bucket" "$PAGE_FILE" 2>/dev/null; then
    sed -i.bak 's|https://your-s3-bucket.s3.amazonaws.com/los-tules-menu.pdf|https://los-tules-menu-files.s3.amazonaws.com/los-tules-menu2026.pdf|g' "$PAGE_FILE"
    rm -f "$PAGE_FILE.bak"
    echo "  Replaced placeholder URL with actual menu bucket URL."
elif grep -q "MENU_PDF_URL" "$PAGE_FILE" 2>/dev/null; then
    echo "  Menu PDF URL constant already present in page.tsx."
else
    echo "  No placeholder URL found to replace. Please verify page.tsx manually."
fi
echo ""

# ============================================
# Step 3: Build the Next.js site
# ============================================
echo "Step 3: Building Next.js site..."
cd "$SITE_DIR"
npm run build
echo "  Site built successfully."
echo ""

# ============================================
# Step 4: Deploy with CDK
# ============================================
echo "Step 4: Deploying with CDK..."
cd "$INFRA_DIR"
source .venv/bin/activate
cdk deploy --require-approval never
echo ""

# ============================================
# Done!
# ============================================
echo "============================================"
echo "  Deployment Complete!"
echo "============================================"
echo ""
echo "Your website is live with the menu PDF bucket."
echo ""
echo "Menu PDF URL:"
echo "  https://los-tules-menu-files.s3.amazonaws.com/los-tules-menu2026.pdf"
echo ""
echo "Check the CDK outputs above for your CloudFront website URL."
echo "============================================"