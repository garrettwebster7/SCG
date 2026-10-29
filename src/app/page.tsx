import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

import { BeforeAfterSlider } from "@/components/before-after-slider";
import { HeroMarquee } from "@/components/hero-marquee";
import { SiteHeader } from "@/components/site-header";
import {
  aboutParagraphs,
  businessName,
  commercialNav,
  coreServices,
  galleryImages,
  homeStats,
  links,
  logos,
  locationKeys,
  locations,
  phoneDisplay,
  processSteps,
  residentialNav,
  tagline,
  testimonials,
  whyScg,
} from "@/lib/site-data";

export const metadata: Metadata = {
  // The money keyword, not the brand, leads the homepage title.
  title: { absolute: "Concrete Contractor in Springfield, IL | Driveways, Patios & Repair" },
  description:
    "Springfield Concrete Group pours and repairs driveways, patios, walkways, slabs and steps in Springfield, IL and nearby communities. Clear written quotes and vetted crews.",
  alternates: { canonical: "/" },
};

// Kept small so the marquee stays light.
const marqueeImages = galleryImages.slice(0, 14);

const homeBeforeAfter = [
  {
    before: "/images/home_driveway_before.jpg",
    after: "/images/home_driveway_after.jpg",
    label: "Driveway Replacement",
  },
  {
    before: "/images/home_patio_before.jpg",
    after: "/images/home_patio_after.jpg",
    label: "Backyard Patio",
  },
];

export default function Home() {
  return (
    <>
      <SiteHeader />
      <main>
        <section className="relative overflow-hidden pb-6 pt-12 md:pt-16">
          <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_20%_30%,rgba(217,146,43,0.18),transparent_45%)]" />
          <div className="relative mx-auto max-w-6xl px-4 text-center md:px-8">
            <Image
              src={logos.stackedOnDark}
              alt={businessName}
              width={788}
              height={457}
              priority
              className="mx-auto mb-6 h-auto w-auto max-w-[240px] drop-shadow-lg md:max-w-[340px]"
            />
            <span className="mb-4 inline-block text-xs font-bold uppercase tracking-[0.22em] text-amber-accent">
              {tagline}
            </span>
            <h1 className="mx-auto mb-5 max-w-4xl font-headline text-4xl leading-[1.05] text-ivory md:text-6xl">
              Concrete You Can Count On in Springfield, IL
            </h1>
            <p className="mx-auto mb-8 max-w-xl text-lg leading-relaxed text-slate-300">
              Driveways, patios, walkways and repairs, built right and quoted clearly.
            </p>
            <div className="flex flex-wrap items-center justify-center gap-3">
              <a href="/#quote" className="cta-primary text-base">
                Get a Free Quote!
              </a>
              <a href={links.call} className="cta-secondary text-base">
                Call {phoneDisplay}
              </a>
            </div>
          </div>
        </section>

        <section aria-label="Recent concrete work" className="pb-4 pt-2">
          <HeroMarquee images={marqueeImages} />
        </section>

        <section className="mx-auto w-full max-w-6xl px-4 pb-8 pt-6 md:px-8">
          <h2 className="mb-6 font-headline text-4xl text-ivory">See the Before &amp; After</h2>
          <div className="grid gap-6 md:grid-cols-2">
            {homeBeforeAfter.map((pair) => (
              <div key={pair.label}>
                <BeforeAfterSlider
                  beforeSrc={pair.before}
                  afterSrc={pair.after}
                  beforeAlt={`${pair.label} before`}
                  afterAlt={`${pair.label} after`}
                />
                <p className="mt-2 text-center text-xs font-semibold uppercase tracking-[0.14em] text-slate-400">
                  {pair.label} · Drag to Compare
                </p>
              </div>
            ))}
          </div>
        </section>

        <section className="mx-auto w-full max-w-6xl px-4 pb-10 pt-6 md:px-8">
          <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
            {homeStats.map((stat) => (
              <div key={stat.label} className="stat-card text-center">
                <p className="stat-value">{stat.value}</p>
                <p className="stat-label">{stat.label}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="mx-auto w-full max-w-6xl px-4 py-10 md:px-8">
          <span className="mb-2 block text-xs font-bold uppercase tracking-[0.22em] text-amber-accent">
            Why SCG
          </span>
          <h2 className="mb-8 font-headline text-4xl text-ivory">One Call, One Clear Quote, One Accountable Company</h2>
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {whyScg.map((item) => (
              <div key={item.title} className="rounded-2xl border border-white/10 bg-white/5 p-6">
                <h3 className="mb-2 font-headline text-xl text-ivory">{item.title}</h3>
                <p className="text-sm leading-relaxed text-slate-300">{item.body}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="mx-auto w-full max-w-6xl px-4 py-10 md:px-8">
          <span className="mb-2 block text-xs font-bold uppercase tracking-[0.22em] text-slate-400">
            Our Services
          </span>
          <h2 className="mb-8 font-headline text-4xl text-ivory">
            Concrete Services in Springfield
          </h2>
          <div className="grid gap-5 md:grid-cols-3">
            {coreServices.map((service) => (
              <Link
                key={service.slug}
                href={`/services/${service.slug}`}
                className="group rounded-2xl border border-amber-accent/30 bg-amber-accent/5 p-6 transition hover:-translate-y-1 hover:border-amber-accent/60 hover:bg-amber-accent/10"
              >
                <h3 className="mb-2 font-headline text-2xl text-ivory">{service.name}</h3>
                <p className="text-sm leading-relaxed text-slate-300">{service.blurb}</p>
                <span className="mt-4 inline-block text-sm font-bold uppercase tracking-[0.12em] text-amber-accent opacity-70 transition group-hover:opacity-100">
                  View {service.navLabel} →
                </span>
              </Link>
            ))}
          </div>
        </section>

        <section id="about" className="mx-auto w-full max-w-6xl scroll-mt-24 px-4 py-12 md:px-8">
          <div className="grid items-center gap-8 md:grid-cols-2">
            <div className="overflow-hidden rounded-2xl border border-white/10 shadow-2xl shadow-black/50">
              <Image
                src="/images/crew_finishing_driveway.jpg"
                alt="Springfield Concrete Group crew bull-floating a freshly poured residential driveway"
                width={1352}
                height={784}
                className="h-full w-full object-cover"
                sizes="(max-width: 768px) 100vw, 50vw"
                quality={90}
                priority
              />
            </div>
            <div>
              <span className="mb-2 block text-xs font-bold uppercase tracking-[0.22em] text-amber-accent">
                About Springfield Concrete Group
              </span>
              <h2 className="mb-4 font-headline text-4xl text-ivory">
                Solid Work. Straight Answers. Built to Last.
              </h2>
              {aboutParagraphs.map((paragraph) => (
                <p key={paragraph.slice(0, 24)} className="mb-4 leading-relaxed text-slate-300">
                  {paragraph}
                </p>
              ))}
              <div className="mt-2 flex flex-wrap items-center gap-4">
                <a href="/#quote" className="cta-primary">
                  Get a Free Quote!
                </a>
                <Link
                  href="/about"
                  className="text-sm font-bold uppercase tracking-[0.12em] text-amber-accent transition hover:text-ivory"
                >
                  More About Us →
                </Link>
              </div>
            </div>
          </div>
        </section>

        <section className="border-y border-white/10 bg-black/20">
          <div className="mx-auto w-full max-w-6xl px-4 py-14 md:px-8">
            <div className="mb-3 text-center">
              <span className="text-xs font-bold uppercase tracking-[0.22em] text-amber-accent">
                How It Works
              </span>
              <h2 className="mt-2 font-headline text-4xl text-ivory">What to Expect</h2>
            </div>
            <p className="mx-auto mb-12 max-w-2xl text-center leading-relaxed text-slate-300">
              Here&apos;s how a project goes from first call to final walkthrough.
            </p>
            <div className="grid gap-6 md:grid-cols-3">
              {processSteps.map((step, i) => (
                <div key={step.title} className="process-step">
                  <span className="process-num">{i + 1}</span>
                  <h3 className="process-title">{step.title}</h3>
                  <p className="process-body">{step.body}</p>
                </div>
              ))}
            </div>
            <div className="mt-10 text-center">
              <a href="/#quote" className="cta-primary">
                Schedule Your Estimate
              </a>
            </div>
          </div>
        </section>

        <section className="mx-auto w-full max-w-6xl px-4 py-14 md:px-8">
          <h2 className="mb-2 font-headline text-4xl text-ivory">
            Residential and Commercial Concrete
          </h2>
          <p className="mb-8 max-w-2xl leading-relaxed text-slate-300">
            From a new driveway to a parking pad for a rental property, we&apos;ll help you choose the
            right option during your free quote.
          </p>
          <div className="grid gap-6 md:grid-cols-2">
            <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
              <h3 className="mb-4 font-headline text-2xl text-amber-accent">Residential Services</h3>
              <div className="flex flex-wrap gap-2">
                {residentialNav.map((item) => (
                  <Link
                    key={`res-${item.slug}-${item.label}`}
                    href={`/services/${item.slug}`}
                    className="rounded-full border border-white/15 bg-black/30 px-4 py-2 text-sm font-semibold text-slate-200 transition hover:border-amber-accent/60 hover:text-ivory"
                  >
                    {item.label}
                  </Link>
                ))}
              </div>
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
              <h3 className="mb-4 font-headline text-2xl text-amber-accent">Commercial Services</h3>
              <div className="flex flex-wrap gap-2">
                {commercialNav.map((item) => (
                  <Link
                    key={`com-${item.slug}-${item.label}`}
                    href={`/services/${item.slug}`}
                    className="rounded-full border border-white/15 bg-black/30 px-4 py-2 text-sm font-semibold text-slate-200 transition hover:border-amber-accent/60 hover:text-ivory"
                  >
                    {item.label}
                  </Link>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* Real reviews only; the section stays hidden until testimonials has entries. */}
        {testimonials.length > 0 && (
          <section id="reviews" className="mx-auto w-full max-w-6xl scroll-mt-24 px-4 pb-14 md:px-8">
            <h2 className="mb-6 font-headline text-4xl text-ivory">What Customers Say</h2>
            <div className="grid gap-4 md:grid-cols-3">
              {testimonials.slice(0, 3).map((item) => (
                <blockquote key={`${item.name}-${item.city}`} className="rounded-2xl border border-white/10 bg-black/20 p-5">
                  <p className="mb-4 text-slate-100">&ldquo;{item.quote}&rdquo;</p>
                  <footer className="text-sm font-semibold text-slate-300">
                    {item.name} · {item.city}
                  </footer>
                </blockquote>
              ))}
            </div>
          </section>
        )}

        <section className="mx-auto w-full max-w-6xl px-4 pb-14 md:px-8">
          <div className="rounded-3xl bg-ivory p-8 text-center text-[#2b2f33] md:p-12">
            <h2 className="mb-3 font-headline text-4xl text-[#2b2f33] md:text-5xl">
              Get Your Free Concrete Quote
            </h2>
            <p className="mx-auto mb-7 max-w-2xl text-[#2b2f33]/80">
              Tell us about your project and we&apos;ll send a free written quote: scope, materials,
              price and timeline. For driveways and slabs we can often start from your address.
            </p>
            <div className="flex flex-wrap justify-center gap-3">
              <a href="/#quote" className="rounded-full bg-[#2b2f33] px-7 py-3.5 text-base font-bold text-white transition hover:bg-[#3a3f44]">
                Get a Free Quote!
              </a>
              <a href={links.call} className="rounded-full border-2 border-[#2b2f33] px-7 py-3.5 text-base font-bold text-[#2b2f33]">
                Call Now
              </a>
              <a href={links.text} className="rounded-full border-2 border-[#2b2f33] px-7 py-3.5 text-base font-bold text-[#2b2f33]">
                Text Now
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
              <div>
                <span className="block font-headline text-2xl text-ivory">{businessName}</span>
                <span className="text-sm text-slate-400">{tagline}</span>
              </div>
              <div className="flex flex-col items-start gap-1 md:items-end">
                <Link
                  href="/privacy-policy"
                  className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-300 transition hover:text-amber-accent"
                >
                  Privacy Policy
                </Link>
                <p className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-300 md:text-right">
                  {businessName} · Springfield, IL · {phoneDisplay}
                </p>
              </div>
            </div>
          </div>
        </footer>
      </main>

      <div className="mobile-bar">
        <a href="/#quote" className="cta-primary flex-1 justify-center">Free Quote!</a>
        <a href={links.call} className="cta-secondary flex-1 justify-center">Call</a>
        <a href={links.text} className="cta-secondary flex-1 justify-center">Text</a>
      </div>
    </>
  );
}
