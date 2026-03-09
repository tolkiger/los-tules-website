"""WebsiteStack - Reusable CDK construct for static website deployment."""

from aws_cdk import (
    Stack,
    RemovalPolicy,
    CfnOutput,
    Size,
    aws_s3 as s3,
    aws_s3_deployment as s3deploy,
    aws_cloudfront as cloudfront,
    aws_cloudfront_origins as origins,
    aws_iam as iam,
    aws_certificatemanager as acm,
    aws_route53 as route53,
    aws_route53_targets as targets,
)
from constructs import Construct
from typing import Optional
import os


class WebsiteStack(Stack):
    """
    CDK Stack for deploying a static website with S3 and CloudFront.
    
    Supports:
    - Custom domains with Route 53 and ACM (optional)
    - CloudFront OAI for S3 access
    - SPA error handling (403/404 -> index.html)
    """

    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        *,
        site_name: str,
        domain_name: Optional[str] = None,
        hosted_zone_id: Optional[str] = None,
        hosted_zone_name: Optional[str] = None,
        content_path: str = "./site/out",
        error_page_path: str = "/index.html",
        **kwargs
    ) -> None:
        """
        Initialize WebsiteStack.
        
        Args:
            site_name: Unique identifier for the website (used in resource names)
            domain_name: Custom domain (e.g., "example.com"). If None, uses CloudFront default domain
            hosted_zone_id: Route 53 hosted zone ID (required if domain_name provided)
            hosted_zone_name: Route 53 hosted zone name (required if domain_name provided)
            content_path: Path to website files (default: "./site/out")
            error_page_path: SPA error page path (default: "/index.html")
        """
        super().__init__(scope, construct_id, **kwargs)

        self._site_name = site_name
        self._domain_name = domain_name
        self._content_path = content_path
        self._error_page_path = error_page_path

        # Validate domain configuration
        if domain_name:
            if not hosted_zone_id or not hosted_zone_name:
                raise ValueError(
                    "hosted_zone_id and hosted_zone_name are required when domain_name is provided"
                )

        # Create resources
        self._website_bucket = self._create_website_bucket()
        self._oai = self._create_oai()
        self._certificate = self._create_certificate(hosted_zone_id, hosted_zone_name) if domain_name else None
        self._distribution = self._create_distribution()
        self._deploy_website_content()
        
        # Optional Route 53 record
        if domain_name:
            self._create_route53_record(hosted_zone_id, hosted_zone_name)
        
        # Create outputs
        self._create_outputs()

    @property
    def website_bucket(self) -> s3.Bucket:
        """The S3 bucket containing website files."""
        return self._website_bucket

    @property
    def distribution(self) -> cloudfront.Distribution:
        """The CloudFront distribution."""
        return self._distribution



    @property
    def website_url(self) -> str:
        """The website URL (custom domain or CloudFront default)."""
        if self._domain_name:
            return f"https://{self._domain_name}"
        return f"https://{self._distribution.distribution_domain_name}"

    def _create_website_bucket(self) -> s3.Bucket:
        """Create private S3 bucket for website content."""
        return s3.Bucket(
            self,
            f"{self._site_name}-website-bucket",
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
        )

    def _create_oai(self) -> cloudfront.OriginAccessIdentity:
        """Create CloudFront Origin Access Identity."""
        oai = cloudfront.OriginAccessIdentity(
            self,
            f"{self._site_name}-oai",
            comment=f"OAI for {self._site_name} website",
        )
        self._website_bucket.grant_read(oai)
        return oai

    def _create_certificate(
        self, hosted_zone_id: str, hosted_zone_name: str
    ) -> acm.Certificate:
        """Create ACM certificate if domain_name provided."""
        hosted_zone = route53.HostedZone.from_hosted_zone_attributes(
            self,
            f"{self._site_name}-hosted-zone",
            hosted_zone_id=hosted_zone_id,
            zone_name=hosted_zone_name,
        )

        return acm.Certificate(
            self,
            f"{self._site_name}-certificate",
            domain_name=self._domain_name,
            validation=acm.CertificateValidation.from_dns(hosted_zone),
        )

    def _create_distribution(self) -> cloudfront.Distribution:
        """Create CloudFront distribution with OAI and error handling."""
        distribution_props = {
            "default_behavior": cloudfront.BehaviorOptions(
                origin=origins.S3Origin(
                    self._website_bucket,
                    origin_access_identity=self._oai,
                ),
                viewer_protocol_policy=cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
            ),
            "default_root_object": "index.html",
            "error_responses": [
                cloudfront.ErrorResponse(
                    http_status=403,
                    response_http_status=200,
                    response_page_path=self._error_page_path,
                ),
                cloudfront.ErrorResponse(
                    http_status=404,
                    response_http_status=200,
                    response_page_path=self._error_page_path,
                ),
            ],
        }

        # Add certificate and domain if configured
        if self._domain_name and self._certificate:
            distribution_props["certificate"] = self._certificate
            distribution_props["domain_names"] = [self._domain_name]

        return cloudfront.Distribution(
            self,
            f"{self._site_name}-distribution",
            **distribution_props,
        )

    def _deploy_website_content(self) -> s3deploy.BucketDeployment:
        """Deploy website files from content_path to S3."""
        return s3deploy.BucketDeployment(
            self,
            f"{self._site_name}-website-deployment",
            sources=[s3deploy.Source.asset(self._content_path)],
            destination_bucket=self._website_bucket,
            distribution=self._distribution,
            distribution_paths=["/*"],
            memory_limit=512,
            ephemeral_storage_size=Size.mebibytes(1024),
            retain_on_delete=False,
            exclude=["*.map", ".git*"],
            wait_for_distribution_invalidation=False,
        )

    def _create_route53_record(
        self, hosted_zone_id: str, hosted_zone_name: str
    ) -> route53.ARecord:
        """Create Route 53 A-record if domain_name provided."""
        hosted_zone = route53.HostedZone.from_hosted_zone_attributes(
            self,
            f"{self._site_name}-hosted-zone-record",
            hosted_zone_id=hosted_zone_id,
            zone_name=hosted_zone_name,
        )

        return route53.ARecord(
            self,
            f"{self._site_name}-alias-record",
            zone=hosted_zone,
            record_name=self._domain_name,
            target=route53.RecordTarget.from_alias(
                targets.CloudFrontTarget(self._distribution)
            ),
        )

    def _create_outputs(self) -> None:
        """Create CloudFormation outputs."""
        CfnOutput(
            self,
            "WebsiteURL",
            value=self.website_url,
            description=f"{self._site_name} Website URL",
        )

        CfnOutput(
            self,
            "CloudFrontDistributionID",
            value=self._distribution.distribution_id,
            description="CloudFront Distribution ID",
        )

        CfnOutput(
            self,
            "WebsiteBucketName",
            value=self._website_bucket.bucket_name,
            description="Website S3 Bucket Name",
        )

        if self._domain_name:
            CfnOutput(
                self,
                "CustomDomainURL",
                value=f"https://{self._domain_name}",
                description="Custom Domain URL",
            )
