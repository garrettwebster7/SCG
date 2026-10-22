import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

import { SiteHeader } from "@/components/site-header";
import {
  businessName,
  clipboardImage,
  links,
  locationKeys,
  locations,
  phoneDisplay,
  trustImage,
} from "@/lib/site-data";

export const metadata: Metadata = {
  title: "About Us | Local Concrete Company in Springfield, IL",
  description:
    "Springfield Concrete Group is a Springfield, Illinois concrete company. Vetted crews, clear written quotes and one company accountable for every project.",
  alternates: { canonical: "/about" },
};

// Core values from the brand guide.
const promises = [
  "Solid: we build it right so it lasts, from base prep to final finish",
  "Straight: clear written quotes, no surprise charges, honest timelines",
  "Local: we live and work here, and our reputation is built one neighbor at a time",
  "Accountable: one company stands behind every pour",
  "Every contractor is screened for experience, references, insurance and quality",
  "We protect your property and leave the job site clean",
];

export default function AboutPage() {
  return (
    <>
      <SiteHeader />
      <main>
        <section className="relative overflow-hidden py-12 md:py-16">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_15%_30%,rgba(217,146,43,0.18),transparent_48%)]" />
          <div className="relative mx-auto grid w-full max-w-6xl gap-10 px-4 md:px-8 lg:grid-cols-2 lg:items-center">
            <div>
              <span className="mb-3 block text-xs font-bold uppercase tracking-[0.22em] text-amber-accent">
                About Us
              </span>
              <h1 className="mb-5 font-headline text-5xl leading-[0.95] text-ivory md:text-6xl">
                About {businessName}
              </h1>
              <p className="mb-4 max-w-lg text-lg leading-relaxed text-slate-300">
                Springfield Concrete Group is a local concrete company serving Springfield, Illinois
                and the surrounding area. Our goal is simple: make hiring a concrete contractor
                simple, honest and predictable. One call, one clear quote, one accountable company.
              </p>
              <div className="flex flex-wrap gap-3">
                <a href="/#quote" className="cta-primary text-base">
                  Get a Free Quote
                </a>
                <a href={links.call} className="cta-secondary text-base">
                  Call {phoneDisplay}
                </a>
              </div>
            </div>
            <div className="overflow-hidden rounded-2xl border border-white/10">
              <Image
                src={trustImage}
                alt="Springfield Concrete Group walking a homeowner through their quote"
                width={1000}
                height={750}
                className="h-full w-full object-cover"
                sizes="(max-width: 1024px) 100vw, 50vw"
                quality={90}
                priority
              />
            </div>
          </div>
        </section>

        <section className="mx-auto w-full max-w-3xl px-4 pb-12 md:px-8">
          <div className="space-y-5 text-lg leading-relaxed text-slate-300">
            <p>
              We handle driveways, patios, walkways, slabs, steps, stamped and decorative concrete,
              and repairs. Every job is done by a vetted crew of independent contractors working under
              the SCG name, standards and warranty, so you get the dependability of a larger company
              and the craftsmanship of local specialists.
            </p>
            <p>
              Every project is held to one standard: proper prep, quality materials, clean finishing
              and clear communication from quote to final walkthrough. That includes base prep,
              drainage and mix choices made for Central Illinois freeze-thaw winters.
            </p>
            <p>
              When you hire SCG, one company is accountable for your project. We want to be the first
              name Central Illinois homeowners and property managers think of for concrete, and we
              plan to earn that one job at a time.
            </p>
          </div>
        </section>

        <section className="mx-auto w-full max-w-6xl px-4 pb-14 md:px-8">
          <div className="grid gap-8 rounded-3xl border border-white/10 bg-white/5 p-6 md:grid-cols-2 md:p-10">
            <div>
              <h2 className="mb-5 font-headline text-3xl text-ivory">What We Stand For</h2>
              <ul className="space-y-3">
                {promises.map((item) => (
                  <li key={item} className="flex items-start gap-3 text-slate-200">
                    <span className="mt-1 text-amber-accent">✓</span>
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>
            <div className="overflow-hidden rounded-2xl border border-white/10">
              <Image
                src={clipboardImage}
                alt="Springfield Concrete Group crew lead preparing a written estimate"
                width={1000}
                height={750}
                className="h-full w-full object-cover"
                sizes="(max-width: 1024px) 100vw, 50vw"
                quality={90}
              />
            </div>
          </div>
        </section>

        <section className="mx-auto w-full max-w-6xl px-4 pb-12 md:px-8" id="quote">
          <div className="rounded-3xl bg-ivory p-8 text-center text-[#2b2f33] md:p-12">
            <h2 className="mb-3 font-headline text-4xl text-[#2b2f33] md:text-5xl">
              Let&apos;s Talk About Your Project
            </h2>
            <p className="mx-auto mb-7 max-w-2xl text-[#2b2f33]/80">
              Whether you need a new driveway, a stamped patio, a slab, a walkway or commercial
              flatwork, we&apos;ll measure, explain the options and send you a free written quote.
            </p>
            <div className="flex flex-wrap justify-center gap-3">
              <a href="/#quote" className="rounded-full bg-[#2b2f33] px-7 py-3.5 text-base font-bold text-white transition hover:bg-[#3a3f44]">
                Get a Free Quote
              </a>
              <a href={links.call} className="rounded-full border-2 border-[#2b2f33] px-7 py-3.5 text-base font-bold text-[#2b2f33]">
                Call Now
              </a>
            </div>
          </div>
        </section>

        <footer className="border-t border-white/10 bg-black/20">
          <div className="mx-auto w-full max-w-6xl px-4 py-8 md:px-8">
            <div className="mb-5 flex flex-wrap gap-2">
              <span className="mr-2 text-xs font-bold uppercase tracking-[0.16em] text-slate-400">
                Serving:
              </span>
              {locationKeys.map((key) => (
                <Link
                  key={key}
                  href={`/${key}`}
                  className="text-sm font-semibold text-slate-300 transition hover:text-amber-accent"
                >
                  {locations[key].city}
                </Link>
              ))}
            </div>
            <div className="flex flex-wrap items-center justify-between gap-4 border-t border-white/10 pt-5">
              <span className="font-headline text-2xl text-ivory">{businessName}</span>
              <div className="flex flex-col items-start gap-1 md:items-end">
                <Link
                  href="/privacy-policy"
                  className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-300 transition hover:text-amber-accent"
                >
                  Privacy Policy
                </Link>
                <p className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-300 md:text-right">
                  {businessName} &middot; Springfield, IL &middot; {phoneDisplay}
                </p>
              </div>
            </div>
          </div>
        </footer>
      </main>

      <div className="mobile-bar">
        <a href="/#quote" className="cta-primary flex-1 justify-center">Free Estimate</a>
        <a href={links.call} className="cta-secondary flex-1 justify-center">Call</a>
        <a href={links.text} className="cta-secondary flex-1 justify-center">Text</a>
      </div>
    </>
  );
}
