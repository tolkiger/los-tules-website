# Los Tules Mexican Restaurant — Complete Deployment Guide

## What Is This?

This is a website for Los Tules Mexican Restaurant. It is built using a
framework called Next.js, which generates all the HTML, CSS, and JavaScript
files that make up the website. Those files get uploaded to Amazon Web
Services (AWS), which serves them to anyone who visits your website URL.

The deploy script also creates a separate storage area for your restaurant
menu PDF, so customers can view or download your menu directly from the
website.

You do NOT need to understand programming to follow this guide. Just follow
each step exactly as written.

---

## How Does This Work? (Simple Explanation)

1. **Next.js** is a tool that builds your website. When you run a "build"
   command, it creates a folder called `out/` that contains plain HTML files
   (the actual web pages), CSS files (the styling/colors), and JavaScript
   files (the interactive features like the photo gallery).

2. **Amazon S3** is like a file storage locker in the cloud. Two separate
   lockers are created:
   - **Website bucket** — holds all the website files (HTML, CSS, JavaScript).
     This bucket is private and can only be accessed through CloudFront.
   - **Menu bucket** — holds your menu PDF file. This bucket is public so
     customers can download the menu directly.

3. **Amazon CloudFront** is a service that sits in front of the website S3
   bucket and makes your website load fast for visitors anywhere in the
   world. It also gives you HTTPS (the padlock icon in the browser).

4. **AWS CDK** is a tool that automatically creates both S3 buckets, the
   CloudFront setup, and all the security settings for you, so you don't
   have to click through the AWS website manually.

5. **The deploy script** (`deploy.sh`) does everything in one command: checks
   your tools are installed, fixes any configuration issues, builds the
   website, uploads your menu PDF, and deploys everything to AWS.

---

## What File Is the Actual Website?

After you run the build command, a folder called `site/out/` is created.
Inside it you will find:

    site/out/
    ├── index.html          <-- THIS IS YOUR HOMEPAGE
    ├── 404.html            <-- This shows if someone visits a bad URL
    ├── _next/
    │   └── static/
    │       ├── css/        <-- All the styling files
    │       ├── chunks/     <-- JavaScript code files
    │       └── media/      <-- Any fonts or assets
    └── favicon.ico         <-- The little icon in the browser tab

**The index.html file is your actual rendered homepage.** Everything in the
out/ folder together makes the complete website. You upload ALL of these
files to S3 (the deploy script does this automatically).

---

## Project Structure

    los-tules-website/
    ├── deploy.sh                       <-- Run this to deploy everything
    ├── README.md                       <-- This file
    ├── site/                           <-- The website code
    │   ├── app/
    │   │   ├── page.tsx                <-- The main website page
    │   │   ├── layout.tsx              <-- Page layout wrapper
    │   │   └── globals.css             <-- Global styles
    │   ├── components/
    │   │   └── ui/                     <-- UI components (buttons, cards)
    │   │       ├── button.tsx
    │   │       └── card.tsx
    │   ├── lib/
    │   │   └── utils.ts                <-- Helper utilities
    │   ├── next.config.ts              <-- Build settings
    │   ├── tailwind.config.ts          <-- Styling settings
    │   ├── postcss.config.mjs          <-- CSS processing settings
    │   ├── tsconfig.json               <-- TypeScript settings
    │   └── package.json                <-- Dependencies list
    └── infra/                          <-- AWS infrastructure code
        ├── app.py                      <-- CDK entry point
        ├── infra/
        │   ├── __init__.py
        │   └── infra_stack.py          <-- What gets created on AWS
        ├── requirements.txt            <-- Python dependencies
        ├── cdk.json                    <-- CDK settings
        └── los-tules-menu2026.pdf      <-- Your menu PDF (you provide this)

---

## Prerequisites (Things You Need to Install First)

### Tool 1: Homebrew (Mac only)

Open Terminal and paste:

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

### Tool 2: Node.js

Mac: brew install node
Windows: Download from https://nodejs.org (LTS version)

Verify: node --version

### Tool 3: Python

Mac: brew install python
Windows: Download from https://www.python.org/downloads/
IMPORTANT: Check "Add Python to PATH" during installation.

Verify: python3 --version

### Tool 4: AWS CLI

Mac: brew install awscli
Windows: Download from https://aws.amazon.com/cli/

Verify: aws --version

### Tool 5: AWS CDK

    npm install -g aws-cdk

Verify: cdk --version

---

## Setting Up Your AWS Account

1. Go to https://aws.amazon.com and create an account
2. Sign in to the AWS Console
3. Click your account name > Security credentials > Access keys
4. Create access key > Command Line Interface > Create
5. COPY BOTH KEYS (you won't see the secret again)

Configure AWS CLI:

    aws configure

Enter:
- AWS Access Key ID: (paste your key)
- AWS Secret Access Key: (paste your secret)
- Default region name: us-east-1
- Default output format: json

Verify: aws sts get-caller-identity

---

## Deployment Steps

### Quick Way (recommended):

    cd los-tules-website
    chmod +x deploy.sh
    ./deploy.sh

The deploy script handles everything automatically:
- Checks that all required tools are installed
- Verifies your AWS credentials are working
- Checks for your menu PDF file
- Installs website dependencies
- Ensures all build configurations are correct
- Fixes the CSS/styling configuration if needed
- Builds the website
- Validates the build output
- Sets up the CDK Python environment
- Creates both S3 buckets and CloudFront
- Uploads the website files and menu PDF
- Shows you the live URL when finished

### Manual Way:

    cd los-tules-website/site
    npm install
    npm run dev              # Test at http://localhost:3000 (Ctrl+C to stop)
    npm run build            # Creates site/out/ folder

    cd ../infra
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt

    # First time only (replace with your account number):
    cdk bootstrap aws://123456789012/us-east-1

    cdk deploy               # Type 'y' when asked. Takes 5-10 min.

The URL will be shown when deployment finishes.

---

## Uploading Your Menu PDF

### Automatic Way (recommended):

1. Place your menu PDF file in the infra folder:

       cp /path/to/your/menu.pdf infra/los-tules-menu2026.pdf

2. Run the deploy script:

       ./deploy.sh

The script automatically uploads the PDF to a public S3 bucket. The
"View Our Menu" buttons on the website already point to the correct URL:

    https://los-tules-menu-files.s3.amazonaws.com/los-tules-menu2026.pdf

### Updating the Menu PDF Later:

1. Replace the file at `infra/los-tules-menu2026.pdf` with the new version
2. Run `./deploy.sh` again

The new PDF will automatically replace the old one.

### Manual Way (without redeploying the whole site):

    aws s3 cp your-menu.pdf s3://los-tules-menu-files/los-tules-menu2026.pdf \
      --content-type "application/pdf"

---

## Updating the Website Later

    cd los-tules-website
    ./deploy.sh

Or manually:

    cd site && npm run build
    cd ../infra && source .venv/bin/activate && cdk deploy

---

## What Gets Created on AWS

When you deploy, the following resources are created:

| Resource | What It Does |
|---|---|
| Website S3 Bucket | Stores the website files (private, only CloudFront can read it) |
| CloudFront Distribution | Serves the website with HTTPS and fast global loading |
| CloudFront OAI | Security link between CloudFront and the website bucket |
| Menu PDF S3 Bucket | Stores the menu PDF (public, customers can download directly) |
| Menu PDF Upload | Automatically copies your PDF from infra/ to the menu bucket |

After deployment, the CDK will show these outputs:

- **WebsiteURL** — Your live website address (share this with customers)
- **MenuPDFURL** — Direct link to the menu PDF
- **CloudFrontDistributionID** — Technical ID (you probably won't need this)
- **WebsiteBucketName** — Name of the website storage bucket
- **MenuBucketName** — Name of the menu PDF storage bucket

---

## Troubleshooting

### The website looks unstyled (no colors, wrong layout)

This means the CSS/Tailwind configuration was incorrect. Run `./deploy.sh`
again — it automatically fixes the Tailwind and PostCSS configuration files
and ensures the CSS directives are present in globals.css.

### The deploy script says a tool is missing

Install the missing tool using the commands in the Prerequisites section
above, then run `./deploy.sh` again.

### AWS credentials error

Run `aws configure` and enter your access key and secret key again. Then
verify with `aws sts get-caller-identity`.

### CDK bootstrap error

If you see a message about bootstrapping, run this (replace the number
with your AWS account number):

    cdk bootstrap aws://YOUR_ACCOUNT_NUMBER/us-east-1

### Menu PDF not loading

- Make sure the file is named exactly `los-tules-menu2026.pdf`
- Make sure it is in the `infra/` folder (not the site/ folder)
- Run `./deploy.sh` again to re-upload it
- Try opening the URL directly in your browser:
  https://los-tules-menu-files.s3.amazonaws.com/los-tules-menu2026.pdf

### Build says "out folder not created"

This usually means there is a code error. Try running these commands to
see the actual error message:

    cd site
    npm run build

### Want to test locally before deploying

    cd site
    npm install
    npm run dev

Then open http://localhost:3000 in your browser. Press Ctrl+C to stop.

---

## Deleting Everything

To remove all AWS resources and stop any charges:

    cd infra
    source .venv/bin/activate
    cdk destroy

Type 'y' when asked to confirm. This deletes both S3 buckets, the
CloudFront distribution, and all related resources. Your local files
are not affected.

---

## Cost

Under $1/month for typical restaurant website traffic. The main costs are:
- S3 storage: a few cents for the website files and menu PDF
- CloudFront: a few cents for serving pages to visitors
- No cost when nobody is visiting the site

---

## Website Features

- **Hero Section** — Full-screen welcome with restaurant name and buttons
- **Sticky Navigation** — Menu bar that follows you as you scroll
- **About Section** — Restaurant story with animated entrance effects
- **Menu Highlights** — Feature cards and a button to view the full menu PDF
- **Photo Gallery** — Grid of images with a lightbox viewer (click to enlarge)
- **Contact Info** — Address, phone number (tap to call on mobile), and hours
- **Map Placeholder** — Directions button that opens Google Maps
- **Mobile Friendly** — Works on phones, tablets, and desktop computers
- **Footer** — Navigation links, contact info, and copyright

---

## 📚 Additional Documentation

This README covers basic deployment. For more detailed guides, see the `docs/` directory:

- **[docs/DOCUMENTATION_INDEX.md](docs/DOCUMENTATION_INDEX.md)** - Complete guide to all documentation
- **[docs/EDITING_GUIDE.md](docs/EDITING_GUIDE.md)** - How to update website content (hours, text, images)
- **[docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** - Common commands and daily workflows
- **[docs/CICD_SETUP_GUIDE.md](docs/CICD_SETUP_GUIDE.md)** - Optional: Automatic deployments with GitHub Actions

**Need help?** Start with [docs/DOCUMENTATION_INDEX.md](docs/DOCUMENTATION_INDEX.md) to find the right guide for your task.
