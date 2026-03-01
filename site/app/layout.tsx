import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Los Tules Mexican Restaurant | Kansas City, MO",
  description:
    "Authentic Mexican food in the heart of Kansas City's Crossroads District. Handmade tortillas, craft margaritas, and family atmosphere since day one.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
