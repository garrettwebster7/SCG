import { businessName, phoneDisplay, phoneHref, services } from "@/lib/site-data";

// TODO: set NEXT_PUBLIC_SITE_URL in Vercel once the domain is live; the fallback is a placeholder.
export const SITE_URL = (process.env.NEXT_PUBLIC_SITE_URL || "https://www.springfieldconcretegroup.com").replace(/\/$/, "");
export const BUSINESS_ID = `${SITE_URL}/#business`;
export const WEBSITE_ID = `${SITE_URL}/#website`;

// Service-area business: locality/region and areaServed only, no street address.
export const SERVICE_AREAS = [
  "Springfield",
  "Chatham",
  "Rochester",
  "Sherman",
  "Riverton",
  "Jacksonville",
  "Taylorville",
  "Petersburg",
  "Auburn",
  "New Berlin",
  "Pleasant Plains",
  "Williamsville",
  "Leland Grove",
];
const REGION = "IL";

const PHONE_E164 = phoneHref.replace(/^tel:/, "");

export function localBusinessSchema() {
  return {
    "@context": "https://schema.org",
    "@type": "HomeAndConstructionBusiness",
    "@id": BUSINESS_ID,
    name: businessName,
    url: SITE_URL,
    telephone: PHONE_E164,
    image: `${SITE_URL}/images/scg-logo-stacked.png`,
    logo: `${SITE_URL}/images/scg-logo-stacked.png`,
    description:
      "Concrete contractor in Springfield, IL. Driveways, patios, walkways, slabs, steps, repairs and stamped concrete for homeowners and property owners across Central Illinois.",
    priceRange: "$$",
    address: {
      "@type": "PostalAddress",
      addressLocality: "Springfield",
      addressRegion: REGION,
      addressCountry: "US",
    },
    geo: {
      "@type": "GeoCoordinates",
      latitude: 39.7817,
      longitude: -89.6501,
    },
    areaServed: SERVICE_AREAS.map((city) => ({ "@type": "City", name: `${city}, ${REGION}` })),
    knowsAbout: services.map((s) => s.name),
    openingHoursSpecification: [
      {
        "@type": "OpeningHoursSpecification",
        dayOfWeek: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
        opens: "07:00",
        closes: "19:00",
      },
    ],
  };
}

export function websiteSchema() {
  return {
    "@context": "https://schema.org",
    "@type": "WebSite",
    "@id": WEBSITE_ID,
    url: SITE_URL,
    name: businessName,
    publisher: { "@id": BUSINESS_ID },
  };
}

export function serviceSchema(opts: {
  name: string;
  serviceType?: string;
  description: string;
  slug: string;
  image?: string;
  url?: string;
}) {
  return {
    "@context": "https://schema.org",
    "@type": "Service",
    name: opts.name,
    serviceType: opts.serviceType ?? opts.name,
    url: opts.url ? `${SITE_URL}${opts.url}` : `${SITE_URL}/services/${opts.slug}`,
    ...(opts.image ? { image: `${SITE_URL}${opts.image}` } : {}),
    description: opts.description,
    provider: { "@id": BUSINESS_ID },
    areaServed: SERVICE_AREAS.map((city) => ({ "@type": "City", name: `${city}, ${REGION}` })),
  };
}

export function breadcrumbSchema(items: { name: string; path: string }[]) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: items.map((item, i) => ({
      "@type": "ListItem",
      position: i + 1,
      name: item.name,
      item: `${SITE_URL}${item.path}`,
    })),
  };
}

export function faqSchema(faqs: { q: string; a: string }[]) {
  return {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: faqs.map((f) => ({
      "@type": "Question",
      name: f.q,
      acceptedAnswer: { "@type": "Answer", text: f.a },
    })),
  };
}

export { phoneDisplay };
