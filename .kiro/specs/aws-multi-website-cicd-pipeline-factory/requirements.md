# Requirements Document

## Introduction

This document specifies the requirements for an AWS Multi-Website CI/CD Pipeline Factory that transforms a single-website AWS CDK deployment into a scalable multi-website architecture. The system follows the AWS-recommended "Pipeline Factory + Shared Construct Library" pattern to manage 10+ websites, each with its own GitHub repository, using AWS-native CI/CD tools (CodePipeline V2, CodeBuild, CodeStar Connections).

The architecture consists of three separate projects:
1. A reusable CDK construct library (pip package) for parameterized website infrastructure
2. A pipeline factory CDK app that generates one CodePipeline per website from JSON configuration
3. A minimal website template that imports the shared construct library

## Glossary

- **Pipeline_Factory**: The CDK application that reads a JSON configuration file and creates AWS CodePipeline stacks for multiple websites
- **Shared_Construct_Library**: A reusable Python pip package containing the WebsiteStack CDK construct
- **WebsiteStack**: The parameterized CDK construct that creates S3, CloudFront, and optional Route 53/ACM resources for a single website
- **Website_Template**: A minimal repository template that each website follows, importing the Shared_Construct_Library
- **OAI**: CloudFront Origin Access Identity, used for secure S3 bucket access (not OAC)
- **Menu_PDF_Bucket**: An optional separate public S3 bucket for hosting PDF files
- **CodeStar_Connection**: AWS service that connects CodePipeline to GitHub repositories
- **Config_File**: The websites.json file containing configuration for all websites
- **Site_Content**: The built static website files located at site/out/ in each repository
- **Custom_Domain**: A user-owned domain name configured with Route 53 and ACM certificate
- **No_Domain_Mode**: Configuration where a website uses CloudFront's default *.cloudfront.net domain

## Requirements

### Requirement 1: Shared Construct Library Package

**User Story:** As a DevOps engineer, I want a reusable CDK construct library, so that I can deploy multiple websites with consistent infrastructure patterns without duplicating code.

#### Acceptance Criteria

1. THE Shared_Construct_Library SHALL be installable as a Python pip package using `pip install -e .`
2. THE Shared_Construct_Library SHALL provide a WebsiteStack construct that accepts the following parameters: site_name (str, required), domain_name (str, optional), hosted_zone_id (str, optional), hosted_zone_name (str, optional), content_path (str, default "./site/out"), error_page_path (str, default "/index.html"), menu_pdf_enabled (bool, default False), menu_pdf_bucket_name (str, optional), menu_pdf_path (str, optional), menu_pdf_filename (str, optional)
3. THE WebsiteStack SHALL create a private S3 bucket with block_public_access enabled for all settings
4. THE WebsiteStack SHALL create a CloudFront Origin Access Identity (OAI) for S3 bucket access
5. THE WebsiteStack SHALL NOT use CloudFront Origin Access Control (OAC)
6. THE WebsiteStack SHALL create a CloudFront Distribution with HTTPS redirect enabled (viewer_protocol_policy=REDIRECT_TO_HTTPS)
7. THE WebsiteStack SHALL configure CloudFront error responses to return /index.html with HTTP 200 for both 403 and 404 errors
8. THE WebsiteStack SHALL create an S3 BucketDeployment that uploads files from content_path to the website bucket
9. THE WebsiteStack SHALL invalidate CloudFront cache paths ["/*"] after S3 deployment
10. THE WebsiteStack SHALL output the following CloudFormation values: WebsiteURL, CloudFrontDistributionID, WebsiteBucketName
11. THE Shared_Construct_Library SHALL include a setup.py file for pip package installation
12. THE Shared_Construct_Library SHALL include unit tests using aws_cdk.assertions
13. THE Shared_Construct_Library SHALL include a README with usage examples for both with-domain and without-domain scenarios

### Requirement 2: Custom Domain Support

**User Story:** As a website owner, I want to use my custom domain name, so that my website is accessible at a branded URL with HTTPS.

#### Acceptance Criteria

1. WHEN domain_name parameter is provided AND is not None AND is not empty string, THE WebsiteStack SHALL create an ACM Certificate for the domain_name
2. WHEN domain_name parameter is provided AND is not None AND is not empty string, THE WebsiteStack SHALL configure the ACM Certificate with DNS validation using the provided hosted_zone_id
3. WHEN domain_name parameter is provided AND is not None AND is not empty string, THE WebsiteStack SHALL set the CloudFront Distribution domain_names property to [domain_name]
4. WHEN domain_name parameter is provided AND is not None AND is not empty string, THE WebsiteStack SHALL create a Route 53 A-record alias pointing to the CloudFront Distribution
5. WHEN domain_name parameter is provided AND is not None AND is not empty string, THE WebsiteStack SHALL require hosted_zone_id and hosted_zone_name parameters
6. WHEN domain_name parameter is None OR empty string, THE WebsiteStack SHALL NOT create an ACM Certificate
7. WHEN domain_name parameter is None OR empty string, THE WebsiteStack SHALL NOT create Route 53 records
8. WHEN domain_name parameter is None OR empty string, THE WebsiteStack SHALL NOT set domain_names property on CloudFront Distribution
9. WHEN domain_name parameter is None OR empty string, THE WebsiteStack SHALL use CloudFront's default *.cloudfront.net domain
10. WHEN domain_name parameter is provided, THE WebsiteStack SHALL output CustomDomainURL with value https://{domain_name}

### Requirement 3: Optional Menu PDF Bucket

**User Story:** As a restaurant website owner, I want to host PDF menus in a separate public bucket, so that menu files are directly accessible without CloudFront caching delays.

#### Acceptance Criteria

1. WHEN menu_pdf_enabled parameter is True, THE WebsiteStack SHALL create a separate S3 bucket for PDF files
2. WHEN menu_pdf_enabled parameter is True AND menu_pdf_bucket_name is provided, THE WebsiteStack SHALL use menu_pdf_bucket_name as the bucket name
3. WHEN menu_pdf_enabled parameter is True, THE WebsiteStack SHALL configure the menu bucket with public read access (block_public_access disabled for all settings)
4. WHEN menu_pdf_enabled parameter is True, THE WebsiteStack SHALL add an IAM policy statement allowing s3:GetObject for AnyPrincipal on the menu bucket
5. WHEN menu_pdf_enabled parameter is True, THE WebsiteStack SHALL set object_ownership to BUCKET_OWNER_PREFERRED on the menu bucket
6. WHEN menu_pdf_enabled parameter is True AND menu_pdf_path is provided AND menu_pdf_filename is provided, THE WebsiteStack SHALL create an S3 BucketDeployment that uploads only the specified PDF file from menu_pdf_path
7. WHEN menu_pdf_enabled parameter is True AND menu_pdf_path is provided AND menu_pdf_filename is provided, THE WebsiteStack SHALL set content_type to "application/pdf" for the BucketDeployment
8. WHEN menu_pdf_enabled parameter is True, THE WebsiteStack SHALL output MenuPDFURL with value https://{bucket_regional_domain_name}/{menu_pdf_filename}
9. WHEN menu_pdf_enabled parameter is True, THE WebsiteStack SHALL output MenuBucketName
10. WHEN menu_pdf_enabled parameter is False, THE WebsiteStack SHALL NOT create a menu PDF bucket
11. WHEN menu_pdf_enabled parameter is False, THE WebsiteStack SHALL NOT create menu PDF outputs

### Requirement 4: Pipeline Factory Configuration

**User Story:** As a DevOps engineer, I want to define all websites in a single JSON configuration file, so that I can manage multiple website pipelines from one central location.

#### Acceptance Criteria

1. THE Pipeline_Factory SHALL read website definitions from a file located at config/websites.json
2. THE Config_File SHALL contain the following top-level fields: connectionArn (string), githubOwner (string), defaultRegion (string), defaultAccount (string), notificationEmail (string), websites (array)
3. THE Config_File websites array SHALL contain objects with the following fields: siteName (string), githubRepo (string), domainName (string), hostedZoneId (string), hostedZoneName (string), menuPdfEnabled (boolean), menuPdfBucketName (string), menuPdfFilename (string)
4. WHEN a Config_File field has value empty string "", THE Pipeline_Factory SHALL interpret it as "not configured"
5. THE Pipeline_Factory SHALL support at least 10 website entries in the websites array
6. THE Pipeline_Factory SHALL validate that siteName values are unique across all website entries
7. THE Pipeline_Factory SHALL validate that githubRepo values are unique across all website entries
8. THE Pipeline_Factory SHALL include unit tests verifying the Config_File schema validation

### Requirement 5: CodePipeline Generation

**User Story:** As a DevOps engineer, I want one AWS CodePipeline created per website, so that each website deploys independently when its GitHub repository is updated.

#### Acceptance Criteria

1. FOR EACH website entry in the Config_File, THE Pipeline_Factory SHALL create a separate CDK stack named {siteName}-pipeline
2. FOR EACH pipeline stack, THE Pipeline_Factory SHALL create an AWS CodePipeline V2 resource
3. FOR EACH pipeline, THE Pipeline_Factory SHALL set trigger_on_push to True
4. FOR EACH pipeline, THE Pipeline_Factory SHALL create a Source stage using CodeStarConnectionsSourceAction
5. FOR EACH pipeline Source stage, THE Pipeline_Factory SHALL configure the GitHub repository as {githubOwner}/{githubRepo}
6. FOR EACH pipeline Source stage, THE Pipeline_Factory SHALL use the connectionArn from the Config_File
7. FOR EACH pipeline Source stage, THE Pipeline_Factory SHALL set the branch to "main"
8. FOR EACH pipeline, THE Pipeline_Factory SHALL create a Build stage using CodeBuildAction
9. FOR EACH pipeline, THE Pipeline_Factory SHALL create an SNS Topic for failure notifications
10. FOR EACH pipeline SNS Topic, THE Pipeline_Factory SHALL subscribe the notificationEmail from the Config_File
11. THE Pipeline_Factory SHALL include unit tests verifying pipeline stack creation for multiple websites

### Requirement 6: CodeBuild Project Configuration

**User Story:** As a DevOps engineer, I want CodeBuild to handle both Next.js builds and CDK deployments, so that website content and infrastructure deploy together automatically.

#### Acceptance Criteria

1. FOR EACH pipeline, THE Pipeline_Factory SHALL create a CodeBuild project with Python 3.12 runtime
2. FOR EACH CodeBuild project, THE Pipeline_Factory SHALL pass the following environment variables: SITE_NAME, DOMAIN_NAME, HOSTED_ZONE_ID, HOSTED_ZONE_NAME, MENU_PDF_ENABLED, MENU_PDF_BUCKET_NAME, MENU_PDF_FILENAME
3. WHEN a Config_File field has value empty string "", THE Pipeline_Factory SHALL set the corresponding environment variable to empty string ""
4. FOR EACH CodeBuild project, THE Pipeline_Factory SHALL grant IAM permissions for: CloudFormation (all actions), S3 (all actions), CloudFront (all actions), Route53 (all actions), ACM (all actions), Lambda (all actions), SSM (all actions)
5. FOR EACH CodeBuild project, THE Pipeline_Factory SHALL grant IAM permission sts:AssumeRole on resources matching pattern arn:aws:iam::*:role/cdk-*
6. FOR EACH CodeBuild project, THE Pipeline_Factory SHALL grant IAM permissions for: iam:PassRole, iam:CreateRole, iam:AttachRolePolicy, iam:PutRolePolicy, iam:DeleteRole, iam:DetachRolePolicy, iam:DeleteRolePolicy, iam:GetRole, iam:TagRole, iam:UntagRole
7. FOR EACH CodeBuild project, THE Pipeline_Factory SHALL use a buildspec.yml file from the website repository
8. FOR EACH CodeBuild project, THE Pipeline_Factory SHALL set the compute type to support Node.js 20 and Python 3.12 installations

### Requirement 7: Website Template Structure

**User Story:** As a website developer, I want a minimal template repository, so that I can quickly create new websites without writing infrastructure code.

#### Acceptance Criteria

1. THE Website_Template SHALL contain a directory structure with: site/out/, infra/, infra/app.py, infra/cdk.json, infra/buildspec.yml, infra/requirements.txt, README.md
2. THE Website_Template infra/requirements.txt SHALL include shared-website-constructs as a dependency
3. THE Website_Template infra/app.py SHALL import WebsiteStack from shared_website_constructs
4. THE Website_Template infra/app.py SHALL read environment variables: SITE_NAME, DOMAIN_NAME, HOSTED_ZONE_ID, HOSTED_ZONE_NAME, MENU_PDF_ENABLED, MENU_PDF_BUCKET_NAME, MENU_PDF_FILENAME
5. WHEN DOMAIN_NAME environment variable is empty string OR not set, THE Website_Template infra/app.py SHALL pass domain_name=None to WebsiteStack
6. WHEN DOMAIN_NAME environment variable is empty string OR not set, THE Website_Template infra/app.py SHALL NOT pass hosted_zone_id or hosted_zone_name to WebsiteStack
7. WHEN MENU_PDF_ENABLED environment variable equals "true", THE Website_Template infra/app.py SHALL pass menu_pdf_enabled=True to WebsiteStack
8. WHEN MENU_PDF_ENABLED environment variable equals "false" OR not set, THE Website_Template infra/app.py SHALL pass menu_pdf_enabled=False to WebsiteStack
9. WHEN MENU_PDF_ENABLED is False, THE Website_Template infra/app.py SHALL NOT pass menu_pdf_bucket_name, menu_pdf_filename, or menu_pdf_path to WebsiteStack
10. THE Website_Template infra/app.py SHALL set content_path to the absolute path of site/out/ relative to the repository root
11. WHEN MENU_PDF_ENABLED is True, THE Website_Template infra/app.py SHALL set menu_pdf_path to the infra/ directory
12. THE Website_Template SHALL include a sample site/out/index.html file
13. THE Website_Template SHALL include a README explaining how to use the template

### Requirement 8: CodeBuild Buildspec

**User Story:** As a website developer, I want the build process to handle Next.js compilation and CDK deployment automatically, so that I only need to push code to trigger a full deployment.

#### Acceptance Criteria

1. THE Website_Template buildspec.yml SHALL define an install phase that installs Node.js 20
2. THE Website_Template buildspec.yml SHALL define an install phase that installs Python 3.12
3. THE Website_Template buildspec.yml SHALL define a pre_build phase that runs `cd site && npm ci && npm run build`
4. THE Website_Template buildspec.yml pre_build phase SHALL create the site/out/ directory with built static files
5. THE Website_Template buildspec.yml SHALL define a build phase that runs `cd infra && pip install -r requirements.txt`
6. THE Website_Template buildspec.yml build phase SHALL run `cd infra && cdk synth`
7. THE Website_Template buildspec.yml build phase SHALL run `cd infra && cdk deploy --all --require-approval never`
8. THE Website_Template buildspec.yml SHALL set CDK_DEFAULT_ACCOUNT environment variable from AWS account context
9. THE Website_Template buildspec.yml SHALL set CDK_DEFAULT_REGION environment variable to us-east-1 OR the value from Config_File defaultRegion

### Requirement 9: Adding New Websites

**User Story:** As a DevOps engineer, I want to add a new website by only updating configuration and deploying, so that scaling to additional websites requires minimal effort.

#### Acceptance Criteria

1. WHEN a new website entry is added to Config_File, THE Pipeline_Factory SHALL create a new pipeline stack for that website when `cdk deploy` is executed
2. WHEN a new website repository is created from Website_Template AND pushed to GitHub, THE corresponding pipeline SHALL trigger automatically
3. WHEN a pipeline is triggered, THE CodeBuild project SHALL execute the buildspec.yml from the website repository
4. WHEN CodeBuild completes successfully, THE website SHALL be accessible at its configured domain OR CloudFront default domain within 10 minutes
5. THE process of adding a new website SHALL require only: creating a GitHub repository from Website_Template, adding an entry to Config_File, running `cdk deploy` in Pipeline_Factory
6. THE process of adding a new website SHALL NOT require modifying any Python code in Pipeline_Factory or Shared_Construct_Library

### Requirement 10: Testing and Validation

**User Story:** As a developer, I want comprehensive unit tests, so that I can verify the infrastructure code works correctly before deployment.

#### Acceptance Criteria

1. THE Shared_Construct_Library SHALL include unit tests for WebsiteStack with domain_name provided AND menu_pdf_enabled=False
2. THE Shared_Construct_Library SHALL include unit tests for WebsiteStack with domain_name provided AND menu_pdf_enabled=True
3. THE Shared_Construct_Library SHALL include unit tests for WebsiteStack with domain_name=None AND menu_pdf_enabled=False
4. THE Shared_Construct_Library SHALL include unit tests for WebsiteStack with domain_name=None AND menu_pdf_enabled=True
5. THE Shared_Construct_Library unit tests SHALL verify that CloudFront Distribution is created with OAI (not OAC)
6. THE Shared_Construct_Library unit tests SHALL verify that ACM Certificate is created only when domain_name is provided
7. THE Shared_Construct_Library unit tests SHALL verify that Route 53 A-record is created only when domain_name is provided
8. THE Shared_Construct_Library unit tests SHALL verify that menu PDF bucket is created only when menu_pdf_enabled=True
9. THE Pipeline_Factory SHALL include unit tests verifying pipeline creation for multiple websites from Config_File
10. THE Pipeline_Factory unit tests SHALL verify that CodeBuild environment variables are set correctly from Config_File
11. THE Pipeline_Factory unit tests SHALL verify that empty string values in Config_File are passed as empty string environment variables
12. ALL unit tests SHALL use aws_cdk.assertions module
13. ALL unit tests SHALL pass when executed with pytest

### Requirement 11: Python-Only Implementation

**User Story:** As a Python developer, I want all code written in Python, so that I can maintain the entire system with a single language and toolchain.

#### Acceptance Criteria

1. THE Shared_Construct_Library SHALL be written entirely in Python
2. THE Pipeline_Factory SHALL be written entirely in Python
3. THE Website_Template infra/app.py SHALL be written entirely in Python
4. THE Shared_Construct_Library setup.py SHALL be written in Python
5. ALL unit tests SHALL be written in Python using pytest
6. THE Pipeline_Factory SHALL NOT contain any TypeScript, JavaScript, or other language code files
7. THE Shared_Construct_Library SHALL NOT contain any TypeScript, JavaScript, or other language code files
8. THE Website_Template infra/ directory SHALL NOT contain any TypeScript, JavaScript, or other language code files

### Requirement 12: AWS-Native CI/CD Only

**User Story:** As a DevOps engineer, I want to use only AWS-native CI/CD services, so that I avoid external dependencies and keep all automation within AWS.

#### Acceptance Criteria

1. THE Pipeline_Factory SHALL use AWS CodePipeline V2 for all pipeline resources
2. THE Pipeline_Factory SHALL use AWS CodeBuild for all build and deployment actions
3. THE Pipeline_Factory SHALL use AWS CodeStar Connections for GitHub integration
4. THE Pipeline_Factory SHALL NOT use GitHub Actions
5. THE Pipeline_Factory SHALL NOT use Jenkins
6. THE Pipeline_Factory SHALL NOT use CircleCI
7. THE Pipeline_Factory SHALL NOT use Travis CI
8. THE Pipeline_Factory SHALL NOT use any third-party CI/CD services
9. THE Website_Template SHALL NOT contain .github/workflows/ directory
10. THE Website_Template SHALL NOT contain any GitHub Actions configuration files

### Requirement 13: CloudFront OAI Pattern

**User Story:** As a DevOps engineer, I want to maintain the current CloudFront Origin Access Identity pattern, so that the migration preserves the existing security model without requiring changes.

#### Acceptance Criteria

1. THE WebsiteStack SHALL create a CloudFront OriginAccessIdentity resource
2. THE WebsiteStack SHALL grant read permissions on the website S3 bucket to the OriginAccessIdentity
3. THE WebsiteStack SHALL configure the CloudFront Distribution origin with origin_access_identity parameter
4. THE WebsiteStack SHALL NOT create a CloudFront OriginAccessControl resource
5. THE WebsiteStack SHALL NOT use origin_access_control parameter on CloudFront Distribution
6. THE WebsiteStack unit tests SHALL verify that OriginAccessIdentity is created
7. THE WebsiteStack unit tests SHALL verify that OriginAccessControl is NOT created

### Requirement 14: Content and Menu PDF Paths

**User Story:** As a website developer, I want the system to use the existing directory structure, so that I don't need to reorganize my repository during migration.

#### Acceptance Criteria

1. THE WebsiteStack SHALL read website content from site/out/ directory relative to repository root
2. THE Website_Template infra/app.py SHALL construct content_path as the absolute path to site/out/
3. WHEN menu_pdf_enabled is True, THE WebsiteStack SHALL read PDF files from the infra/ directory
4. WHEN menu_pdf_enabled is True, THE Website_Template infra/app.py SHALL set menu_pdf_path to the infra/ directory absolute path
5. THE WebsiteStack BucketDeployment for website content SHALL use content_path parameter as the source
6. WHEN menu_pdf_enabled is True, THE WebsiteStack BucketDeployment for menu PDF SHALL use menu_pdf_path as the source directory
7. WHEN menu_pdf_enabled is True AND menu_pdf_filename is provided, THE WebsiteStack SHALL filter the BucketDeployment to include only the specified PDF filename
8. THE Website_Template buildspec.yml SHALL create site/out/ directory by running `npm run build` in the site/ directory

### Requirement 15: Documentation

**User Story:** As a new team member, I want comprehensive documentation, so that I can understand and use the system without extensive guidance.

#### Acceptance Criteria

1. THE Shared_Construct_Library SHALL include a README.md file
2. THE Shared_Construct_Library README SHALL document all WebsiteStack parameters with descriptions and examples
3. THE Shared_Construct_Library README SHALL include usage examples for websites with custom domains
4. THE Shared_Construct_Library README SHALL include usage examples for websites without custom domains
5. THE Shared_Construct_Library README SHALL include usage examples for websites with menu PDF buckets
6. THE Pipeline_Factory SHALL include a README.md file
7. THE Pipeline_Factory README SHALL document the Config_File schema with all required and optional fields
8. THE Pipeline_Factory README SHALL include step-by-step instructions for one-time AWS setup (CodeStar Connection, CDK bootstrap)
9. THE Pipeline_Factory README SHALL include instructions for deploying all pipelines
10. THE Pipeline_Factory README SHALL include instructions for adding a new website
11. THE Website_Template SHALL include a README.md file
12. THE Website_Template README SHALL explain how to use the template for a new website
13. THE Website_Template README SHALL document the required environment variables
14. THE Website_Template README SHALL explain the directory structure and file purposes
