#!/usr/bin/env python3
"""
CDK Entry Point -- Uses shared website construct + adds menu PDF bucket.

The shared-website-constructs code is included locally in this repo.
We add the menu PDF bucket separately since it's specific to Los Tules.
"""
import os
import aws_cdk as cdk
from shared_website_constructs import WebsiteStack
from aws_cdk import (
    aws_s3 as s3,
    aws_s3_deployment as s3deploy,
    aws_iam as iam,
    CfnOutput,
    RemovalPolicy,
)

app = cdk.App()

# Read environment variables (injected by CodeBuild)
site_name = os.environ.get("SITE_NAME", "los-tules-website")

# Domain configuration - convert empty strings to None
domain_name = os.environ.get("DOMAIN_NAME", "").strip() or None
hosted_zone_id = os.environ.get("HOSTED_ZONE_ID", "").strip() or None
hosted_zone_name = os.environ.get("HOSTED_ZONE_NAME", "").strip() or None

# Menu PDF configuration
menu_pdf_enabled = os.environ.get("MENU_PDF_ENABLED", "true").lower() == "true"
menu_pdf_bucket_name = os.environ.get("MENU_PDF_BUCKET_NAME", "los-tules-menu-files")
menu_pdf_filename = os.environ.get("MENU_PDF_FILENAME", "los-tules-menu2026.pdf")

# Debug: Print environment variables
print(f"DEBUG: SITE_NAME={site_name}")
print(f"DEBUG: DOMAIN_NAME={domain_name}")
print(f"DEBUG: HOSTED_ZONE_ID={hosted_zone_id}")
print(f"DEBUG: HOSTED_ZONE_NAME={hosted_zone_name}")

# Build paths relative to this file
infra_dir = os.path.dirname(os.path.abspath(__file__))
content_path = os.path.join(infra_dir, "..", "site", "out")

# Create the main website stack
website_stack = WebsiteStack(
    app,
    "LosTulesWebsiteStack",
    site_name=site_name,
    domain_name=domain_name,  # None = uses CloudFront default domain
    hosted_zone_id=hosted_zone_id,
    hosted_zone_name=hosted_zone_name,
    content_path=content_path,
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT"),
        region=os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    ),
    description="Los Tules Mexican Restaurant - Static Website on AWS with Menu PDF Bucket",
)

# Add menu PDF bucket if enabled
if menu_pdf_enabled:
    # Create public menu PDF bucket
    menu_bucket = s3.Bucket(
        website_stack,
        "LosTulesMenuBucket",
        bucket_name=menu_pdf_bucket_name,
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

    # Add public read policy
    menu_bucket.add_to_resource_policy(
        iam.PolicyStatement(
            actions=["s3:GetObject"],
            resources=[menu_bucket.arn_for_objects("*")],
            principals=[iam.AnyPrincipal()],
        )
    )

    # Deploy menu PDF
    s3deploy.BucketDeployment(
        website_stack,
        "LosTulesMenuDeployment",
        sources=[s3deploy.Source.asset(
            infra_dir,
            exclude=["*", f"!{menu_pdf_filename}"],
        )],
        destination_bucket=menu_bucket,
        content_type="application/pdf",
    )

    # Output menu PDF URL
    CfnOutput(
        website_stack,
        "MenuPDFURL",
        value=f"https://{menu_bucket.bucket_regional_domain_name}/{menu_pdf_filename}",
        description="Los Tules Menu PDF URL",
    )

    CfnOutput(
        website_stack,
        "MenuBucketName",
        value=menu_bucket.bucket_name,
        description="Menu PDF S3 Bucket Name",
    )

app.synth()
