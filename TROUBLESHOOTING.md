# Troubleshooting Guide

This document describes recovery scripts available if you encounter issues.

## When Dependencies Break

If you get npm errors or dependency conflicts:

```bash
cd site
bash fix-and-reinstall.sh
```

This script:
- Removes old `node_modules` and `package-lock.json`
- Installs compatible versions of all dependencies
- Reinstalls everything fresh

## When CSS/Styling Breaks

If Tailwind CSS or styling stops working:

```bash
cd site
bash fix-css.sh
```

This script:
- Replaces `globals.css` with a clean version
- Updates `tailwind.config.ts` with proper theme colors
- Fixes the button and card components

## Normal Development

For regular development, use:

```bash
cd site
npm run dev
```

Then open http://localhost:3000 in your browser.
