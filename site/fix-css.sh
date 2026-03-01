#!/bin/bash
set -euo pipefail

# ============================================================
#  Fix: Replace globals.css with a clean version
# ============================================================
#
#  Make sure you are inside the site folder first:
#
#    cd ~/Desktop/los-tules-website/site
#
#  Then run:
#
#    bash fix-css.sh
#
# ============================================================

echo ""
echo "🔧 Fixing globals.css..."
echo ""

cat > app/globals.css << 'CSSEOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

html {
  scroll-behavior: smooth;
}

body {
  margin: 0;
  padding: 0;
  background-color: #fafaf9;
  color: #1c1917;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

*,
*::before,
*::after {
  box-sizing: border-box;
  border-width: 0;
  border-style: solid;
  border-color: #e7e5e4;
}
CSSEOF

echo "  ✅ app/globals.css replaced"
echo ""

# Also update tailwind.config.ts to include the CSS variable theme
cat > tailwind.config.ts << 'TWEOF'
import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        border: "#e7e5e4",
        input: "#e7e5e4",
        ring: "#1c1917",
        background: "#fafaf9",
        foreground: "#1c1917",
        primary: {
          DEFAULT: "#1c1917",
          foreground: "#fafaf9",
        },
        secondary: {
          DEFAULT: "#f5f5f4",
          foreground: "#1c1917",
        },
        destructive: {
          DEFAULT: "#ef4444",
          foreground: "#fafaf9",
        },
        muted: {
          DEFAULT: "#f5f5f4",
          foreground: "#78716c",
        },
        accent: {
          DEFAULT: "#f5f5f4",
          foreground: "#1c1917",
        },
        card: {
          DEFAULT: "#ffffff",
          foreground: "#1c1917",
        },
        popover: {
          DEFAULT: "#ffffff",
          foreground: "#1c1917",
        },
      },
      borderRadius: {
        lg: "0.5rem",
        md: "calc(0.5rem - 2px)",
        sm: "calc(0.5rem - 4px)",
      },
    },
  },
  plugins: [],
};

export default config;
TWEOF

echo "  ✅ tailwind.config.ts updated with theme colors"
echo ""

# Update the button component to use direct colors instead of CSS variables
cat > components/ui/button.tsx << 'BTNEOF'
import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-stone-400 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-stone-900 text-stone-50 hover:bg-stone-800",
        destructive: "bg-red-500 text-stone-50 hover:bg-red-600",
        outline: "border border-stone-300 bg-white hover:bg-stone-100 hover:text-stone-900",
        secondary: "bg-stone-100 text-stone-900 hover:bg-stone-200",
        ghost: "hover:bg-stone-100 hover:text-stone-900",
        link: "text-stone-900 underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-md px-8",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button";
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };
BTNEOF

echo "  ✅ components/ui/button.tsx updated"
echo ""

# Update the card component to use direct colors
cat > components/ui/card.tsx << 'CARDEOF'
import * as React from "react";
import { cn } from "@/lib/utils";

const Card = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn("rounded-lg border border-stone-200 bg-white text-stone-900 shadow-sm", className)} {...props} />
  )
);
Card.displayName = "Card";

const CardHeader = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn("flex flex-col space-y-1.5 p-6", className)} {...props} />
  )
);
CardHeader.displayName = "CardHeader";

const CardTitle = React.forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLHeadingElement>>(
  ({ className, ...props }, ref) => (
    <h3 ref={ref} className={cn("text-2xl font-semibold leading-none tracking-tight", className)} {...props} />
  )
);
CardTitle.displayName = "CardTitle";

const CardDescription = React.forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLParagraphElement>>(
  ({ className, ...props }, ref) => (
    <p ref={ref} className={cn("text-sm text-stone-500", className)} {...props} />
  )
);
CardDescription.displayName = "CardDescription";

const CardContent = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn("p-6 pt-0", className)} {...props} />
  )
);
CardContent.displayName = "CardContent";

const CardFooter = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn("flex items-center p-6 pt-0", className)} {...props} />
  )
);
CardFooter.displayName = "CardFooter";

export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent };
CARDEOF

echo "  ✅ components/ui/card.tsx updated"
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  ✅ All fixes applied!                    ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Now restart the dev server:"
echo ""
echo "    npm run dev"
echo ""
echo "  Then open http://localhost:3000"
echo ""
