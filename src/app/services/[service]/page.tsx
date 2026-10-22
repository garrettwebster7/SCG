import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { ServicePage } from "@/components/service-page";
import { getService, isCityServicePair, serviceSlugs } from "@/lib/site-data";

type PageProps = {
  params: Promise<{ service: string }>;
};

export function generateStaticParams() {
  return serviceSlugs.map((service) => ({ service }));
}

export const dynamicParams = false;

// Slugs with a bespoke /springfield/<slug> page. This page must NOT title itself "<Service> Springfield IL"
// for those, or two of our pages compete for the same phrase. Other services keep the city in the title.
const SLUGS_WITH_OWN_SPRINGFIELD_PAGE = new Set(
  serviceSlugs.filter((slug) => isCityServicePair("springfield", slug)),
);

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { service } = await params;
  const content = getService(service);

  if (!content) {
    return { title: "Service Not Found" };
  }

  // The root layout's title template appends "| Springfield Concrete Group".
  const hasOwnCityPage = SLUGS_WITH_OWN_SPRINGFIELD_PAGE.has(content.slug);
  const title = hasOwnCityPage ? content.name : `${content.name} Springfield IL`;
  const ogTitle = hasOwnCityPage
    ? `${content.name} | Springfield Concrete Group`
    : `${content.name} in Springfield, IL | Springfield Concrete Group`;

  return {
    title,
    description: content.blurb,
    alternates: { canonical: `/services/${content.slug}` },
    openGraph: {
      title: ogTitle,
      description: content.blurb,
      images: [content.image],
      type: "website",
    },
  };
}

export default async function ServiceRoutePage({ params }: PageProps) {
  const { service } = await params;
  const content = getService(service);

  if (!content) {
    notFound();
  }

  return <ServicePage service={content} />;
}
