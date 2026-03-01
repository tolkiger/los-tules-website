# Domain Management Plan

This document outlines the recommended approach for managing Route 53 hosted zones and GoDaddy domain configuration for all 10 websites.

## Overview

After successfully migrating Los Tules to the shared-website-constructs library, the next step is to set up a centralized domain management system that:

1. Creates Route 53 hosted zones for all domains
2. Optionally automates GoDaddy nameserver updates via API
3. Provides hosted zone IDs for website stacks to reference
4. Keeps domain/DNS configuration separate from website deployments

## Architecture

```
┌─────────────────────────────────────┐
│   domain-management (CDK App)       │
│                                     │
│   Creates:                          │
│   - Route 53 Hosted Zones           │
│   - Outputs Zone IDs & Nameservers  │
│   - Optional: GoDaddy API Updates   │
└─────────────────────────────────────┘
                  │
                  │ Outputs: Zone IDs
                  ▼
┌─────────────────────────────────────┐
│   website-1, website-2, ... (CDKs)  │
│                                     │
│   References:                       │
│   - Hosted Zone ID (from above)     │
│   - Creates ACM Certificate         │
│   - Creates CloudFront + Domain     │
└─────────────────────────────────────┘
```

## Benefits

1. **Separation of Concerns**: DNS changes rarely, websites change often
2. **Faster CI/CD**: Website deployments don't wait for DNS propagation
3. **Centralized Management**: All domains in one place
4. **Safer**: DNS changes are deliberate, not accidental
5. **Reusable**: Hosted zones created once, referenced by multiple stacks

## Implementation Options

### Option 1: Manual Nameserver Updates (Simplest)

**Pros:**
- Simple to implement
- No API keys needed
- Works immediately

**Cons:**
- Manual step for each domain (one-time, ~2 minutes per domain)

**Steps:**
1. Create `domain-management` CDK app
2. Deploy to create all hosted zones
3. Copy nameservers from outputs
4. Update each domain in GoDaddy console
5. Wait for DNS propagation (5-30 minutes)

### Option 2: Automated GoDaddy Updates (Recommended)

**Pros:**
- Fully automated
- Infrastructure as Code
- Repeatable

**Cons:**
- Requires GoDaddy API key
- More complex setup

**Steps:**
1. Get GoDaddy API key (production environment)
2. Store API key in AWS Secrets Manager
3. Create Lambda function to call GoDaddy API
4. Use CDK Custom Resource to trigger Lambda
5. Lambda updates nameservers automatically

## Recommended Structure

```
domain-management/
├── app.py                      # CDK entry point
├── domain_management/
│   ├── __init__.py
│   ├── hosted_zone_stack.py    # Creates Route 53 zones
│   └── godaddy_updater.py      # Optional: Lambda for GoDaddy API
├── config/
│   └── domains.json            # List of all domains
├── lambda/
│   └── godaddy_updater/        # Lambda function code
│       ├── index.py
│       └── requirements.txt
├── cdk.json
├── requirements.txt
└── README.md
```

## Configuration File Format

`config/domains.json`:
```json
{
  "domains": [
    {
      "name": "lostuleskc.com",
      "description": "Los Tules Mexican Restaurant",
      "godaddyDomain": "lostuleskc.com",
      "autoUpdate": true
    },
    {
      "name": "website-b.com",
      "description": "Website B",
      "godaddyDomain": "website-b.com",
      "autoUpdate": true
    }
    // ... 8 more domains
  ],
  "godaddy": {
    "apiKeySecretName": "godaddy-api-key",
    "apiSecretSecretName": "godaddy-api-secret",
    "environment": "production"
  }
}
```

## GoDaddy API Integration

### Prerequisites

1. **Get GoDaddy API Key:**
   - Go to https://developer.godaddy.com/keys
   - Create production API key
   - Save the key and secret

2. **Store in AWS Secrets Manager:**
   ```bash
   aws secretsmanager create-secret \
     --name godaddy-api-key \
     --secret-string "your-api-key"
   
   aws secretsmanager create-secret \
     --name godaddy-api-secret \
     --secret-string "your-api-secret"
   ```

### Lambda Function

The Lambda function will:
1. Receive hosted zone nameservers from CDK Custom Resource
2. Retrieve GoDaddy API credentials from Secrets Manager
3. Call GoDaddy API to update nameservers
4. Return success/failure to CDK

**GoDaddy API Endpoint:**
```
PATCH https://api.godaddy.com/v1/domains/{domain}/records/NS
```

**Request Body:**
```json
[
  {
    "data": "ns-123.awsdns-12.com",
    "name": "@",
    "ttl": 3600,
    "type": "NS"
  },
  // ... 3 more nameservers
]
```

## Implementation Plan

### Phase 1: Create Domain Management Stack (No Automation)

**Week 1:**
1. Create `domain-management` CDK app
2. Add all 10 domains to `config/domains.json`
3. Create `HostedZoneStack` that creates all zones
4. Deploy and get nameservers
5. Manually update GoDaddy for all 10 domains
6. Wait for DNS propagation
7. Document hosted zone IDs

**Deliverables:**
- All 10 hosted zones created in Route 53
- All 10 domains pointing to Route 53
- List of hosted zone IDs for website stacks

### Phase 2: Add GoDaddy Automation (Optional)

**Week 2:**
1. Get GoDaddy API key
2. Store credentials in Secrets Manager
3. Create Lambda function for GoDaddy API calls
4. Add CDK Custom Resource to trigger Lambda
5. Test with a new domain
6. Document the automation

**Deliverables:**
- Automated nameserver updates
- Lambda function for GoDaddy API
- Documentation for adding new domains

### Phase 3: Update Website Stacks

**Week 3:**
1. Update Los Tules with domain configuration
2. Deploy and verify custom domain works
3. Update pipeline-factory config for all websites
4. Deploy pipelines
5. Test CI/CD with domain configuration

**Deliverables:**
- Los Tules accessible at lostuleskc.com
- All 10 websites configured with domains
- CI/CD pipelines working with custom domains

## Cost Estimate

- **Route 53 Hosted Zones**: $0.50/month per zone = $5/month for 10 zones
- **Route 53 Queries**: ~$0.40/month per million queries (negligible for 10 sites)
- **Lambda Executions**: Free tier covers GoDaddy API calls
- **Secrets Manager**: $0.40/month per secret = $0.80/month for 2 secrets

**Total**: ~$6/month for domain management infrastructure

## Next Steps After Los Tules Migration

1. **Verify Los Tules works** at CloudFront URL
2. **Create domain-management CDK app** (I can scaffold this)
3. **Decide on automation**: Manual or GoDaddy API?
4. **Deploy domain-management stack**
5. **Update Los Tules with domain** after DNS propagation
6. **Roll out to remaining 9 websites**

## Sample Code Snippets

### HostedZoneStack (domain-management/hosted_zone_stack.py)

```python
from aws_cdk import Stack, aws_route53 as route53, CfnOutput
from constructs import Construct
import json

class HostedZoneStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs):
        super().__init__(scope, construct_id, **kwargs)
        
        # Load domains from config
        with open("config/domains.json") as f:
            config = json.load(f)
        
        # Create hosted zone for each domain
        for domain_config in config["domains"]:
            domain_name = domain_config["name"]
            
            zone = route53.PublicHostedZone(
                self,
                f"{domain_name.replace('.', '-')}-zone",
                zone_name=domain_name,
                comment=domain_config.get("description", ""),
            )
            
            # Output zone ID
            CfnOutput(
                self,
                f"{domain_name}-zone-id",
                value=zone.hosted_zone_id,
                description=f"Hosted Zone ID for {domain_name}",
                export_name=f"{domain_name}-zone-id",
            )
            
            # Output nameservers
            CfnOutput(
                self,
                f"{domain_name}-nameservers",
                value=", ".join(zone.hosted_zone_name_servers or []),
                description=f"Nameservers for {domain_name}",
            )
            
            # Optional: Trigger GoDaddy update
            if domain_config.get("autoUpdate", False):
                # Add Custom Resource here to call Lambda
                pass
```

### Website Stack Update (los-tules-website/infra/app.py)

```python
# After domain-management is deployed, update to:
export DOMAIN_NAME="lostuleskc.com"
export HOSTED_ZONE_ID="Z1234567890ABC"  # From domain-management output
export HOSTED_ZONE_NAME="lostuleskc.com"

# Then redeploy:
cdk deploy
```

## Questions to Answer

Before implementing, we need to decide:

1. **Manual or Automated?** 
   - Manual: 20 minutes one-time setup for 10 domains
   - Automated: 2-3 hours development + GoDaddy API key

2. **When to implement?**
   - Now: Before migrating other websites
   - Later: After Los Tules is verified working

3. **All domains at once or incremental?**
   - All at once: Create all 10 zones, update all 10 domains
   - Incremental: Start with Los Tules, add others as needed

## My Recommendation

**For your situation (10 websites, production environment):**

1. **Today**: Verify Los Tules works without domain
2. **This Week**: Create domain-management stack with manual updates
3. **Next Week**: Add Los Tules domain, verify it works
4. **Following Weeks**: Add remaining 9 domains incrementally
5. **Optional**: Add GoDaddy automation if you plan to add more domains frequently

This approach balances speed, safety, and maintainability.
