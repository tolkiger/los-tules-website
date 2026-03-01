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
        # Menu PDF S3 Bucket
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
        # Deploy menu PDF to menu bucket
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
