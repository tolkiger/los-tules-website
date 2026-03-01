#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="$SCRIPT_DIR/site"
INFRA_DIR="$SCRIPT_DIR/infra"
CDK_STACK_FILE="$INFRA_DIR/stacks/infra_stack.py"
MENU_PDF="$INFRA_DIR/los-tules-menu2026.pdf"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Los Tules — Website Deployment         ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ============================================
# Prerequisites Check
# ============================================
echo "🔍 Checking required tools..."
echo ""

MISSING=0

if ! command -v node &> /dev/null; then
    echo "  ❌ Node.js is NOT installed. Install: brew install node"
    MISSING=1
else
    echo "  ✅ Node.js $(node --version)"
fi

if ! command -v npm &> /dev/null; then
    echo "  ❌ npm is NOT installed."
    MISSING=1
else
    echo "  ✅ npm $(npm --version)"
fi

if ! command -v python3 &> /dev/null; then
    echo "  ❌ Python 3 is NOT installed. Install: brew install python"
    MISSING=1
else
    echo "  ✅ Python $(python3 --version 2>&1 | cut -d' ' -f2)"
fi

if ! command -v aws &> /dev/null; then
    echo "  ❌ AWS CLI is NOT installed. Install: brew install awscli"
    MISSING=1
else
    echo "  ✅ AWS CLI $(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)"
fi

if ! command -v cdk &> /dev/null; then
    echo "  ❌ AWS CDK is NOT installed. Install: npm install -g aws-cdk"
    MISSING=1
else
    echo "  ✅ AWS CDK $(cdk --version 2>&1 | cut -d' ' -f1)"
fi

echo ""

if [ "$MISSING" -eq 1 ]; then
    echo "❌ Some tools are missing. Install them and try again."
    exit 1
fi

# ============================================
# AWS Credentials Check
# ============================================
echo "🔑 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "  ❌ AWS credentials not configured. Run: aws configure"
    exit 1
fi
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "  ✅ Authenticated as account: $ACCOUNT_ID"
echo ""

# ============================================
# Menu PDF Check
# ============================================
echo "📄 Checking for menu PDF..."
if [ -f "$MENU_PDF" ]; then
    MENU_SIZE=$(du -h "$MENU_PDF" | cut -f1)
    echo "  ✅ Menu PDF found ($MENU_SIZE)"
else
    echo "  ⚠️  Menu PDF not found at: $MENU_PDF"
    echo "     The 'View Our Menu' buttons will link to a placeholder URL."
    echo "     To include the menu, place 'los-tules-menu2026.pdf' in the infra/ directory."
    echo ""
    read -p "     Continue without menu PDF? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo ""

# ============================================
# Step 1: Install Dependencies
# ============================================
echo "📦 Step 1: Installing site dependencies..."
cd "$SITE_DIR"

if [ ! -d "node_modules" ]; then
    echo "   Installing dependencies..."
    npm install
    echo ""
else
    echo "  ✅ node_modules already exists."
fi
echo ""

# ============================================
# Step 2: Verify Next.js Config
# ============================================
echo "⚙️  Step 2: Verifying Next.js static export config..."

cat > "$SITE_DIR/next.config.ts" << 'NEXTCONFIG'
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
NEXTCONFIG

echo "  ✅ next.config.ts set to static export."
echo ""

# ============================================
# Step 3: Verify Tailwind & PostCSS Config
# ============================================
echo "🎨 Step 3: Verifying Tailwind and PostCSS configuration..."

cat > "$SITE_DIR/postcss.config.mjs" << 'POSTCSS'
/** @type {import('postcss-load-config').Config} */
const config = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};

export default config;
POSTCSS

cat > "$SITE_DIR/tailwind.config.ts" << 'TAILWIND'
import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};

export default config;
TAILWIND

echo "  ✅ Tailwind and PostCSS configs verified."
echo ""

# ============================================
# Step 4: Verify globals.css Tailwind Directives
# ============================================
echo "🖌️  Step 4: Verifying globals.css Tailwind directives..."

GLOBALS_CSS="$SITE_DIR/app/globals.css"

if [ ! -f "$GLOBALS_CSS" ]; then
    echo "   Creating globals.css with Tailwind directives..."
    cat > "$GLOBALS_CSS" << 'CSSFIX'
@tailwind base;
@tailwind components;
@tailwind utilities;
CSSFIX
    echo "  ✅ globals.css created."
elif ! head -3 "$GLOBALS_CSS" | grep -q "@tailwind base"; then
    echo "   Fixing globals.css — prepending Tailwind directives..."
    TEMP_FILE=$(mktemp)
    cat > "$TEMP_FILE" << 'CSSFIX'
@tailwind base;
@tailwind components;
@tailwind utilities;

CSSFIX
    cat "$GLOBALS_CSS" >> "$TEMP_FILE"
    mv "$TEMP_FILE" "$GLOBALS_CSS"
    echo "  ✅ Tailwind directives added to globals.css."
else
    echo "  ✅ globals.css already has Tailwind directives."
fi
echo ""

# ============================================
# Step 5: Build the Next.js Site
# ============================================
echo "🔨 Step 5: Building the website..."
cd "$SITE_DIR"
npm run build

if [ ! -d "out" ]; then
    echo "  ❌ Build failed — 'out' folder not created."
    exit 1
fi

FILE_COUNT=$(find out -type f | wc -l | tr -d ' ')
echo ""

if [ "$FILE_COUNT" -lt 3 ]; then
    echo "  ❌ Build may have failed — only $FILE_COUNT files generated."
    exit 1
fi

echo "  ✅ Website built! ($FILE_COUNT files)"
echo ""

# ============================================
# Step 6: Set Up CDK Python Environment
# ============================================
echo "🐍 Step 6: Setting up CDK..."
cd "$INFRA_DIR"

if [ ! -d ".venv" ]; then
    echo "   Creating Python virtual environment..."
    python3 -m venv .venv
fi

source .venv/bin/activate
pip install -q -r requirements.txt
echo "  ✅ CDK environment ready."
echo ""

# ============================================
# Step 7: Verify CDK Stack
# ============================================
echo "📝 Step 7: Verifying CDK stack..."

if [ ! -f "$CDK_STACK_FILE" ]; then
    echo "  ❌ CDK stack file not found at: $CDK_STACK_FILE"
    exit 1
fi

echo "  ✅ CDK stack file exists."
echo ""

# ============================================
# Step 8: CDK Bootstrap Check
# ============================================
echo "🏗️  Step 8: Checking CDK bootstrap..."
if ! aws cloudformation describe-stacks --stack-name CDKToolkit --region us-east-1 &> /dev/null; then
    echo "   Bootstrapping CDK (one-time, ~2 minutes)..."
    cdk bootstrap "aws://$ACCOUNT_ID/us-east-1"
fi
echo "  ✅ CDK bootstrapped."
echo ""

# ============================================
# Step 9: Deploy to AWS
# ============================================
echo "🚀 Step 9: Deploying to AWS..."
echo "   First deploy takes 5-10 minutes."
echo ""

cdk deploy --require-approval broadening

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   ✅ Deployment Complete!                ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Your website is LIVE! Look above for the WebsiteURL."
echo ""
echo "Resources deployed:"
echo "  • Website S3 bucket (private, served via CloudFront)"
echo "  • CloudFront distribution with HTTPS"
echo "  • Menu PDF S3 bucket (public read access)"
echo "  • Menu PDF auto-uploaded from infra/ directory"
echo ""
if [ -f "$MENU_PDF" ]; then
echo "Menu PDF URL:"
echo "  https://los-tules-menu-files.s3.amazonaws.com/los-tules-menu2026.pdf"
echo ""
fi
echo "To update later, just run ./deploy.sh again."
echo ""