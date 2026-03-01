#!/bin/bash
set -euo pipefail

# ============================================================
#  Fix: Update package.json with compatible versions
# ============================================================
#
#  HOW TO USE:
#  1. Make sure you are inside the los-tules-website/site folder:
#
#       cd ~/Desktop/los-tules-website/site
#
#  2. Paste this entire script into your terminal and press Enter.
#     OR save it as a file and run it:
#
#       nano fix-and-reinstall.sh
#       (paste, Ctrl+X, Y, Enter)
#       chmod +x fix-and-reinstall.sh
#       ./fix-and-reinstall.sh
#
# ============================================================

echo ""
echo "🔧 Fixing package.json with compatible versions..."
echo ""

# Remove old node_modules and lock file
rm -rf node_modules package-lock.json

# Write corrected package.json
cat > package.json << 'PKGEOF'
{
  "name": "los-tules-website",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "^15.1.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "lucide-react": "^0.469.0",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.6.0",
    "@radix-ui/react-slot": "^1.1.1"
  },
  "devDependencies": {
    "typescript": "^5.7.0",
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "tailwindcss": "^3.4.17",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.4.49"
  }
}
PKGEOF

echo "  ✅ package.json updated with compatible versions"
echo ""
echo "📦 Installing dependencies (this may take 1-2 minutes)..."
echo ""

npm install

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  ✅ Fixed! Dependencies installed.        ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Now test the site:"
echo ""
echo "    npm run dev"
echo ""
echo "  Then open http://localhost:3000 in your browser."
echo ""
