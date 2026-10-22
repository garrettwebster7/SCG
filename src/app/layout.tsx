import type { Metadata } from "next";
import { Inter, Oswald } from "next/font/google";

import { Clarity } from "@/components/clarity";
import { JsonLd } from "@/components/json-ld";
import { QuoteModalRoot } from "@/components/quote-modal";
import { VercelInsights } from "@/components/vercel-insights";
import { localBusinessSchema, websiteSchema } from "@/lib/seo";
import { siteUrl } from "@/lib/site-data";
import "./globals.css";

const headline = Oswald({
  variable: "--font-headline",
  weight: ["400", "500", "600", "700"],
  subsets: ["latin"],
});

const body = Inter({
  variable: "--font-body",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: {
    default: "Springfield Concrete Group | Concrete Driveways, Patios & Repair in Springfield, IL",
    template: "%s | Springfield Concrete Group",
  },
  description:
    "Springfield Concrete Group builds and repairs concrete driveways, patios, walkways, slabs and steps in Springfield, IL and nearby communities. Clear written quotes and vetted crews.",
  metadataBase: new URL(siteUrl),
  alternates: { canonical: "/" },
  openGraph: {
    title: "Springfield Concrete Group",
    description: "Solid work. Straight answers. Concrete driveways, patios and repairs in Springfield, IL.",
    url: siteUrl,
    siteName: "Springfield Concrete Group",
    type: "website",
    // Solid background, not transparent: iMessage and WhatsApp render a transparent logo as a black square in dark mode.
    // TODO: replace with an SCG share image (stacked logo on white, 2000x2000).
    images: [
      {
        url: "/images/og-image.png",
        width: 1200,
        height: 630,
        type: "image/png",
        alt: "Springfield Concrete Group",
      },
    ],
  },
  twitter: {
    // The artwork is square; summary_large_image would crop it.
    card: "summary",
    title: "Springfield Concrete Group",
    description: "Solid work. Straight answers. Concrete driveways, patios and repairs in Springfield, IL.",
    images: ["/images/og-image.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${headline.variable} ${body.variable} antialiased`}>
      <body className="min-h-screen">
        <JsonLd data={[localBusinessSchema(), websiteSchema()]} />
        {/*
          Overflow guard here, not on html/body: on iPhone Safari a root overflow rule makes position: fixed
          elements (the bottom bar) slide while scrolling.
        */}
        <div className="site-clip">{children}</div>
        <QuoteModalRoot />
        <VercelInsights />
        <Clarity />
      </body>
    </html>
  );
}
