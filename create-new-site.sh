#!/bin/bash
set -euo pipefail

# ============================================
# Static Website Template Creator
# ============================================
# This script creates a new website project based on the Los Tules template
# Usage: ./create-new-site.sh <project-name> <business-name> <bucket-name>
# Example: ./create-new-site.sh pizza-palace "Pizza Palace" pizza-palace-menu-files

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Static Website Template Creator        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ============================================
# Validate Arguments
# ============================================
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <project-name> <business-name> <bucket-name>"
    echo ""
    echo "Arguments:"
    echo "  project-name   : Directory name for the new project (e.g., pizza-palace)"
    echo "  business-name  : Display name for the business (e.g., \"Pizza Palace\")"
    echo "  bucket-name    : S3 bucket name for menu PDFs (e.g., pizza-palace-menu-files)"
    echo ""
    echo "Example:"
    echo "  $0 pizza-palace \"Pizza Palace\" pizza-palace-menu-files"
    echo ""
    exit 1
fi

PROJECT_NAME="$1"
BUSINESS_NAME="$2"
BUCKET_NAME="$3"

# Validate project name (lowercase, hyphens only)
if ! [[ "$PROJECT_NAME" =~ ^[a-z0-9-]+$ ]]; then
    echo "❌ Error: project-name must contain only lowercase letters, numbers, and hyphens"
    exit 1
fi

# Validate bucket name (S3 naming rules)
if ! [[ "$BUCKET_NAME" =~ ^[a-z0-9-]+$ ]]; then
    echo "❌ Error: bucket-name must contain only lowercase letters, numbers, and hyphens"
    exit 1
fi

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEW_PROJECT_DIR="$(dirname "$TEMPLATE_DIR")/$PROJECT_NAME"

echo "📋 Configuration:"
echo "  Project Name:    $PROJECT_NAME"
echo "  Business Name:   $BUSINESS_NAME"
echo "  Menu Bucket:     $BUCKET_NAME"
echo "  Template Source: $TEMPLATE_DIR"
echo "  New Project:     $NEW_PROJECT_DIR"
echo ""

# ============================================
# Check if project already exists
# ============================================
if [ -d "$NEW_PROJECT_DIR" ]; then
    echo "❌ Error: Directory '$NEW_PROJECT_DIR' already exists"
    echo "   Please choose a different project name or remove the existing directory"
    exit 1
fi

# ============================================
# Create new project directory
# ============================================
echo "📁 Creating project directory..."
mkdir -p "$NEW_PROJECT_DIR"
echo "  ✅ Created: $NEW_PROJECT_DIR"
echo ""

# ============================================
# Copy template files
# ============================================
echo "📋 Copying template files..."

# Copy main directories
cp -r "$TEMPLATE_DIR/site" "$NEW_PROJECT_DIR/"
cp -r "$TEMPLATE_DIR/infra" "$NEW_PROJECT_DIR/"
cp -r "$TEMPLATE_DIR/.kiro" "$NEW_PROJECT_DIR/"
cp -r "$TEMPLATE_DIR/docs" "$NEW_PROJECT_DIR/"

# Copy root files
cp "$TEMPLATE_DIR/.gitignore" "$NEW_PROJECT_DIR/"
cp "$TEMPLATE_DIR/deploy.sh" "$NEW_PROJECT_DIR/"
cp "$TEMPLATE_DIR/README.md" "$NEW_PROJECT_DIR/"

echo "  ✅ Files copied"
echo ""

# ============================================
# Clean up build artifacts and dependencies
# ============================================
echo "🧹 Cleaning build artifacts..."

rm -rf "$NEW_PROJECT_DIR/site/node_modules"
rm -rf "$NEW_PROJECT_DIR/site/.next"
rm -rf "$NEW_PROJECT_DIR/site/out"
rm -rf "$NEW_PROJECT_DIR/infra/.venv"
rm -rf "$NEW_PROJECT_DIR/infra/cdk.out"
rm -rf "$NEW_PROJECT_DIR/infra/__pycache__"
rm -rf "$NEW_PROJECT_DIR/infra/stacks/__pycache__"

# Remove template-specific files
rm -f "$NEW_PROJECT_DIR/infra/los-tules-menu2026.pdf"
rm -f "$NEW_PROJECT_DIR/update_with_menu_bucket.sh"
rm -f "$NEW_PROJECT_DIR/create-new-site.sh"

echo "  ✅ Cleaned"
echo ""

# ============================================
# Update configuration files
# ============================================
echo "⚙️  Updating configuration files..."

# Update package.json
sed -i.bak "s/los-tules-website/$PROJECT_NAME/g" "$NEW_PROJECT_DIR/site/package.json"
rm -f "$NEW_PROJECT_DIR/site/package.json.bak"

# Update CDK stack name in app.py
sed -i.bak "s/LosTulesWebsiteStack/${PROJECT_NAME^}Stack/g" "$NEW_PROJECT_DIR/infra/app.py"
sed -i.bak "s/Los Tules Mexican Restaurant/$BUSINESS_NAME/g" "$NEW_PROJECT_DIR/infra/app.py"
rm -f "$NEW_PROJECT_DIR/infra/app.py.bak"

# Update bucket name in infra_stack.py
sed -i.bak "s/los-tules-menu-files/$BUCKET_NAME/g" "$NEW_PROJECT_DIR/infra/stacks/infra_stack.py"
sed -i.bak "s/LosTules/${PROJECT_NAME^}/g" "$NEW_PROJECT_DIR/infra/stacks/infra_stack.py"
sed -i.bak "s/Los Tules/$BUSINESS_NAME/g" "$NEW_PROJECT_DIR/infra/stacks/infra_stack.py"
rm -f "$NEW_PROJECT_DIR/infra/stacks/infra_stack.py.bak"

# Update README.md
sed -i.bak "s/Los Tules Mexican Restaurant/$BUSINESS_NAME/g" "$NEW_PROJECT_DIR/README.md"
sed -i.bak "s/los-tules-website/$PROJECT_NAME/g" "$NEW_PROJECT_DIR/README.md"
sed -i.bak "s/los-tules-menu-files/$BUCKET_NAME/g" "$NEW_PROJECT_DIR/README.md"
rm -f "$NEW_PROJECT_DIR/README.md.bak"

echo "  ✅ Configuration updated"
echo ""

# ============================================
# Create placeholder content file
# ============================================
echo "📝 Creating content customization guide..."

cat > "$NEW_PROJECT_DIR/CUSTOMIZE.md" << EOF
# Customize Your Website

This project was created from the static website template.

## Quick Start

1. **Update website content**: Edit \`site/app/page.tsx\`
   - Change business name, tagline, description
   - Update contact information (address, phone, hours)
   - Modify gallery images
   - Update about section

2. **Add your menu PDF**: Place your menu PDF in \`infra/\` directory
   - Name it: \`${PROJECT_NAME}-menu.pdf\`
   - Update the filename in \`infra/stacks/infra_stack.py\` (line ~125)

3. **Update styling**: Edit \`site/app/globals.css\` and Tailwind classes

4. **Deploy**: Run \`./deploy.sh\`

## Key Files to Customize

### Content
- \`site/app/page.tsx\` - Main website content
- \`site/app/layout.tsx\` - Page metadata (title, description)

### Infrastructure
- \`infra/stacks/infra_stack.py\` - AWS resources
- \`infra/app.py\` - CDK app configuration

### Styling
- \`site/app/globals.css\` - Global styles
- \`site/tailwind.config.ts\` - Tailwind configuration

## Configuration

**Project Name**: $PROJECT_NAME
**Business Name**: $BUSINESS_NAME
**Menu Bucket**: $BUCKET_NAME
**CDK Stack**: ${PROJECT_NAME^}Stack

## Documentation

See \`docs/DOCUMENTATION_INDEX.md\` for complete documentation.

## Next Steps

1. Install dependencies: \`cd site && npm install\`
2. Test locally: \`npm run dev\`
3. Customize content in \`site/app/page.tsx\`
4. Add your menu PDF to \`infra/\`
5. Deploy: \`./deploy.sh\`
EOF

echo "  ✅ Created CUSTOMIZE.md"
echo ""

# ============================================
# Create .env.example file
# ============================================
cat > "$NEW_PROJECT_DIR/.env.example" << EOF
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=your-account-id

# Project Configuration
PROJECT_NAME=$PROJECT_NAME
BUSINESS_NAME=$BUSINESS_NAME
MENU_BUCKET_NAME=$BUCKET_NAME
EOF

echo "  ✅ Created .env.example"
echo ""

# ============================================
# Initialize git repository
# ============================================
echo "🔧 Initializing git repository..."
cd "$NEW_PROJECT_DIR"
git init
git add .
git commit -m "Initial commit: $BUSINESS_NAME website from template"
echo "  ✅ Git repository initialized"
echo ""

# ============================================
# Success!
# ============================================
echo "╔══════════════════════════════════════════╗"
echo "║   ✅ Project Created Successfully!       ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "📁 Project Location: $NEW_PROJECT_DIR"
echo ""
echo "🚀 Next Steps:"
echo ""
echo "1. Navigate to project:"
echo "   cd $NEW_PROJECT_DIR"
echo ""
echo "2. Read customization guide:"
echo "   cat CUSTOMIZE.md"
echo ""
echo "3. Install dependencies:"
echo "   cd site && npm install"
echo ""
echo "4. Test locally:"
echo "   npm run dev"
echo "   # Visit http://localhost:3000"
echo ""
echo "5. Customize content:"
echo "   # Edit site/app/page.tsx"
echo "   # Add menu PDF to infra/"
echo ""
echo "6. Deploy to AWS:"
echo "   cd .. && ./deploy.sh"
echo ""
echo "📚 Documentation: docs/DOCUMENTATION_INDEX.md"
echo ""
