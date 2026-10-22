// Central site content: homepage, location pages, header and SEO read from here.

export const businessName = "Springfield Concrete Group";
export const businessShortName = "SCG";
export const tagline = "Solid work. Straight answers.";
// TODO: real phone. Change these three together (display, tel: and sms: links).
export const phoneDisplay = "(217) 555-0100";
export const phoneHref = "tel:+12175550100";
export const textHref = "sms:+12175550100";
// TODO: real domain. Also set NEXT_PUBLIC_SITE_URL in Vercel.
export const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "https://www.springfieldconcretegroup.com";

// Logos (transparent PNGs, SVGs alongside). The header, hero and footer sit on charcoal, so they use the
// "-on-dark" variants (light lettering). Horizontal is 715x138, stacked 788x457.
export const logos = {
  stacked: "/images/scg-logo-stacked.png",
  stackedOnDark: "/images/scg-logo-stacked-on-dark.png",
  horizontal: "/images/scg-logo-horizontal.png",
  horizontalLight: "/images/scg-logo-horizontal-on-dark.png",
  monogram: "/images/scg-monogram.png",
};

export type LocationKey =
  | "springfield"
  | "chatham"
  | "sherman"
  | "rochester"
  | "riverton"
  | "jacksonville"
  | "taylorville"
  | "petersburg";

export const locationKeys: LocationKey[] = [
  "springfield",
  "chatham",
  "sherman",
  "rochester",
  "riverton",
  "jacksonville",
  "taylorville",
  "petersburg",
];

export type ServiceGroup = "core" | "concrete" | "hardscaping";

export type Service = {
  slug: string;
  name: string;
  // "a Concrete Driveway quote", not "Driveways". Only set when it differs from `name`; read via serviceSingular().
  singular?: string;
  navLabel: string;
  group: ServiceGroup;
  blurb: string;
  intro: string;
  bullets: string[];
  image: string;
  showcaseImage?: string;
  beforeAfter?: BeforeAfterPair;
};

export const serviceSingular = (s: Pick<Service, "name" | "singular">): string => s.singular ?? s.name;

export const services: Service[] = [
  // Core 6: shown in nav and homepage.
  {
    slug: "concrete-driveways",
    name: "Concrete Driveways",
    singular: "Concrete Driveway",
    navLabel: "Driveways",
    group: "core",
    blurb:
      "New pours and replacements with proper base, reinforcement and control joints for long-lasting strength.",
    intro:
      "Your driveway carries your vehicles every day and sits through every Central Illinois freeze and thaw. We pour new driveways and replace failed ones in Springfield with a compacted base, reinforcement and properly spaced control joints, so the new slab outlasts the old one.",
    bullets: [
      "New installs or full tear-out and re-pour",
      "Compacted base and reinforcement",
      "Control joints cut to direct cracking",
      "Free written quote",
    ],
    image: "/images/residential_driveway_concrete.png",
    beforeAfter: {
      before: "/images/before_driveway.png",
      after: "/images/after_driveway.png",
      label: "Driveway Replacement",
    },
  },
  {
    slug: "concrete-patios",
    name: "Patios & Walkways",
    singular: "Patio & Walkway",
    navLabel: "Patios & Walkways",
    group: "core",
    blurb:
      "Plain, broom-finish, stamped or decorative options that fit your home and budget.",
    intro:
      "A concrete patio or walkway gives you usable outdoor space with very little upkeep. We pour patios, front walks and side paths in Springfield in broom, smooth, stamped or decorative finishes, graded so water runs away from your house.",
    bullets: [
      "Broom, smooth or stamped finishes",
      "Graded to drain away from the house",
      "Front walks, side paths and back patios",
      "Free written quote",
    ],
    image: "/images/decorative_stampted_back_patio.png",
    showcaseImage: "/images/walkway_concrete_front_of_house.png",
    beforeAfter: {
      before: "/images/back_patio_before.png",
      after: "/images/back_patio_after.png",
      label: "Backyard Patio",
    },
  },
  {
    slug: "concrete-slabs-flatwork",
    name: "Slabs & Pads",
    singular: "Slab & Pad",
    navLabel: "Slabs & Pads",
    group: "core",
    blurb:
      "Garage, shed, AC, deck and footing slabs poured level and built to load.",
    intro:
      "A slab has one job: stay flat under the load you put on it. We pour garage, shed, AC, deck and footing slabs in Springfield on a compacted base, reinforced for what will sit on them and finished level.",
    bullets: [
      "Garage and shed slabs",
      "AC, generator and equipment pads",
      "Deck and footing slabs",
      "Free written quote",
    ],
    image: "/images/residential_driveway_concrete_2.png",
    showcaseImage: "/images/workers_pouring_driveway_live_action.png",
  },
  {
    slug: "steps-stoops-landings",
    name: "Steps & Stoops",
    singular: "Steps & Stoop",
    navLabel: "Steps & Stoops",
    group: "core",
    blurb:
      "Safe, code-conscious concrete steps and entries.",
    intro:
      "Steps and stoops get used every day and have to be right: even risers, solid footing and a surface that isn't slick. We build and replace concrete steps, stoops and entry landings in Springfield, and tie them into your existing walk or porch.",
    bullets: [
      "Front stoops and entry landings",
      "Even, code-conscious risers",
      "Tied into existing walks and porches",
      "Free written quote",
    ],
    image: "/images/front_walkway+driveway.png",
    showcaseImage: "/images/walkway_concrete_front_of_house.png",
  },
  {
    slug: "concrete-repair-resurfacing",
    name: "Repair & Resurfacing",
    navLabel: "Repair & Resurfacing",
    group: "core",
    blurb:
      "Crack repair, leveling, patching and resurfacing to extend the life of existing concrete.",
    intro:
      "Not every tired slab needs to be torn out. Where the base is still sound, we repair cracks, patch damaged sections and resurface worn concrete in Springfield for less than a full replacement. If replacement is the better call, we'll tell you.",
    bullets: [
      "Crack and joint repair",
      "Patching and resurfacing",
      "No tear-out when the base is sound",
      "Free written quote",
    ],
    image: "/images/after_cracked_concrete_driveway.png",
    showcaseImage: "/images/driveway_close_up_detailed_8k.png",
    beforeAfter: {
      before: "/images/before_cracked_concrete_driveway.png",
      after: "/images/after_cracked_concrete_driveway.png",
      label: "Cracked Driveway Repair",
    },
  },
  {
    slug: "stamped-decorative-concrete",
    name: "Stamped & Decorative Concrete",
    navLabel: "Stamped & Decorative",
    group: "core",
    blurb:
      "Patterns, colors and textures that elevate outdoor spaces.",
    intro:
      "Stamped and decorative concrete gives a patio, walkway or entry the look of stone, slate or brick for less than those materials cost to install. We pour, stamp, color and seal decorative concrete in Springfield.",
    bullets: [
      "Stone, slate and brick patterns",
      "Integral and accent colors",
      "Sealed to protect color and pattern",
      "Free written quote",
    ],
    image: "/images/decorative_stamped_driveway.png",
    showcaseImage: "/images/stampted_patio_2.png",
  },

  {
    slug: "walkways-sidewalks",
    name: "Walkways & Sidewalks",
    singular: "Walkway & Sidewalk",
    navLabel: "Walkways",
    group: "concrete",
    blurb:
      "Concrete walkways, paths and sidewalks poured level and tied into your property.",
    intro:
      "A level, well-drained walkway makes a property safer and easier to use. We pour front walks, side paths and sidewalk sections in Springfield, matched as closely as possible to the concrete you already have.",
    bullets: [
      "Front walks and side paths",
      "Sidewalk section replacement",
      "Level, slip-aware finishes",
      "Free written quote",
    ],
    image: "/images/walkway_concrete_front_of_house.png",
    showcaseImage: "/images/front_walkway+driveway.png",
  },
  {
    slug: "concrete-removal-replacement",
    name: "Concrete Removal & Replacement",
    navLabel: "Removal & Replacement",
    group: "concrete",
    blurb:
      "We break out old, failed concrete, fix the base and pour a new slab.",
    intro:
      "When concrete is too far gone to repair, we handle the whole job: break out the old slab, haul it off, correct the base and drainage that caused the failure, and pour new. One company, one written price.",
    bullets: [
      "Full demo and haul-off",
      "Base and drainage corrected",
      "Driveways, patios and walkways",
      "Free written quote",
    ],
    image: "/images/workers_pouring_driveway_live_action.png",
    beforeAfter: {
      before: "/images/before_cracked_concrete_driveway.png",
      after: "/images/after_cracked_concrete_driveway.png",
      label: "Removal & Replacement",
    },
  },
  {
    slug: "commercial-flatwork",
    name: "Commercial Flatwork",
    navLabel: "Commercial",
    group: "concrete",
    blurb:
      "Concrete flatwork for landlords, property managers and small commercial properties in the Springfield area.",
    intro:
      "We handle concrete flatwork for landlords, property managers and small commercial properties around Springfield: written scopes, scheduling that works around your tenants, and one company accountable for the result.",
    bullets: [
      "Sidewalks and walkways",
      "Parking pads and approach slabs",
      "Footings and small slabs",
      "Free written quote",
    ],
    image: "/images/walkway_entryway-commercial.png",
    showcaseImage: "/images/commercial-entryway-clean.png",
  },
  {
    slug: "commercial-sidewalks-walkways",
    name: "Commercial Sidewalks & Walkways",
    singular: "Commercial Sidewalk & Walkway",
    navLabel: "Commercial Walkways",
    group: "concrete",
    blurb:
      "Sidewalk and entry walkway concrete for offices, retail, rentals and medical properties.",
    intro:
      "We pour and replace sidewalks and entry walkways for rental properties, offices, retail and medical buildings in the Springfield area. Work is planned around foot traffic so access stays clear while we're on site.",
    bullets: [
      "Entryways, sidewalk runs and tie-ins",
      "Clean transitions and safe surfaces",
      "Sequenced to limit disruption",
      "Free site quote",
    ],
    image: "/images/commercial-sidewalk-entry-way-medical.png",
    showcaseImage: "/images/walkway_entryway-commercial.png",
  },
  {
    slug: "commercial-parking-approach-slabs",
    name: "Parking Pads & Approach Slabs",
    singular: "Parking Pad & Approach Slab",
    navLabel: "Parking Pads",
    group: "concrete",
    blurb:
      "Parking pads and approach slabs for commercial and multi-unit properties.",
    intro:
      "We pour parking pads, approach slabs and dumpster pads built for daily traffic. Staging, pours and cure time are scheduled so your property keeps working.",
    bullets: [
      "Parking, approach and dumpster pads",
      "Built for load and drainage",
      "Phased scheduling to protect access",
      "Free written quote",
    ],
    image: "/images/loadnig_dock_commercial.png",
    showcaseImage: "/images/hoa_sidewalk_commercial.png",
  },
  {
    slug: "commercial-concrete-repair-resurfacing",
    name: "Commercial Repair & Resurfacing",
    navLabel: "Commercial Repair",
    group: "concrete",
    blurb:
      "Crack repair, patching and resurfacing to extend slab life without full replacement.",
    intro:
      "Not every commercial slab needs replacing. We repair cracks, patch damaged sections and resurface worn concrete so your property stays safe and presentable, and we tell you plainly when replacement is the better spend.",
    bullets: [
      "Crack and joint repair",
      "Targeted patching and resurfacing",
      "Trip-hazard and section repairs",
      "Free written quote",
    ],
    image: "/images/commercial-entryway-clean.png",
    showcaseImage: "/images/hoa_sidewalk_commercial.png",
  },
];

export const coreServices = services.filter((s) => s.group === "core");
export const concreteServices = services.filter((s) => s.group === "concrete");
export const hardscapingServices = services.filter((s) => s.group === "hardscaping");
export const serviceSlugs = services.map((s) => s.slug);
export function getService(slug: string): Service | undefined {
  return services.find((s) => s.slug === slug);
}

// Service FAQs (also emitted as FAQPage structured data). Per business policy, no price figures, warranty
// claims or licensing claims.
export type FaqItem = { q: string; a: string };

const universalServiceFaqs: FaqItem[] = [
  {
    q: "Do you offer free estimates in Springfield?",
    a: "Yes. Every estimate is free and in writing. For many projects we can scope it from satellite imagery and confirm the details on a short visit.",
  },
  {
    q: "What areas around Springfield do you serve?",
    a: "Springfield and nearby communities, including Chatham, Sherman, Rochester, Riverton, Jacksonville, Taylorville and Petersburg.",
  },
];

const serviceFaqMap: Record<string, FaqItem[]> = {
  "concrete-driveways": [
    {
      q: "How long does a new concrete driveway take?",
      a: "Most residential driveways take one to three days on site, depending on size and whether we're removing an old slab. Stay off it on foot for about 24 hours and keep vehicles off for roughly seven days while it cures.",
    },
    {
      q: "Should I repair or replace my driveway?",
      a: "Isolated cracks or surface wear can often be repaired or resurfaced. Widespread cracking, sinking sections or a failed base call for a tear-out and re-pour. We'll tell you which one yours needs.",
    },
    {
      q: "How thick should a concrete driveway be?",
      a: "For standard passenger vehicles we typically pour four inches over a compacted base, and go thicker where heavier trucks park. Base prep matters as much as thickness.",
    },
  ],
  "concrete-patios": [
    {
      q: "How long does a concrete patio take?",
      a: "Most patios are poured and finished in one to two days once the site is prepped. You can walk on it after about 24 hours, and it keeps gaining strength over the following weeks.",
    },
    {
      q: "What finishes can I get?",
      a: "Broom, smooth-troweled, exposed aggregate, and stamped or colored decorative finishes. We'll show you options that fit the house and the budget.",
    },
    {
      q: "Can you match a new walkway to my existing concrete?",
      a: "We match width, finish and joint spacing as closely as we can. New concrete is lighter than cured concrete, so expect a slight color difference that fades over a season or two.",
    },
  ],
  "stamped-decorative-concrete": [
    {
      q: "How long does stamped concrete last?",
      a: "With proper installation and a re-seal every couple of years, stamped concrete lasts for decades. The sealer protects the color and pattern from sun, water and de-icing salt.",
    },
    {
      q: "Is stamped concrete cheaper than pavers or natural stone?",
      a: "It usually installs for less than pavers or natural stone while still giving you a stone, slate or brick look.",
    },
    {
      q: "Does stamped concrete get slippery?",
      a: "It can when wet. On walkways, steps and pool surrounds we add a non-slip additive to the sealer to improve traction.",
    },
  ],
  "concrete-slabs-flatwork": [
    {
      q: "What are concrete slabs used for?",
      a: "Garages, sheds, AC and generator pads, hot tubs, decks and footings. We size the base and reinforcement for the load so the slab doesn't crack or settle.",
    },
  ],
  "steps-stoops-landings": [
    {
      q: "Can you replace just my front steps or stoop?",
      a: "Yes. We replace steps, stoops and landings on their own and tie the finish into your existing walk or porch.",
    },
  ],
  "concrete-repair-resurfacing": [
    {
      q: "When is repair worth it instead of replacement?",
      a: "If the slab is structurally sound with surface cracks, scaling or a worn finish, repair or resurfacing restores it for less than replacement. If the base has failed or sections are sinking, replacement is the better long-term call. We'll give you a straight answer after we look at it.",
    },
    {
      q: "What causes the surface flaking I see after winter?",
      a: "That's usually scaling from freeze-thaw cycles and de-icing salt working on the top layer. Resurfacing and sealing can address it if the slab underneath is sound.",
    },
  ],
};

export function getServiceFaqs(slug: string): FaqItem[] {
  const specific = serviceFaqMap[slug] ?? [];
  return [...specific, ...universalServiceFaqs];
}

// Excludes site-wide answers so city+service pages don't repeat them.
export function getServiceSpecificFaqs(slug: string): FaqItem[] {
  return serviceFaqMap[slug] ?? [];
}

// A /[city]/[service] page exists only if it has hand-written copy in `cityServiceLocalContent`; the pair
// list is derived from it. Templated pages are treated by Google as duplicates and not indexed; pairs
// without an entry 301 to /services/<slug> (next.config.ts).
export type CityServiceContent = {
  service: Service;
  city: string;
  locationKey: LocationKey;
  neighborhoods: string[];
  metaTitle: string;
  metaDescription: string;
  heading: string;
  paragraphs: string[];
  projectExample: string | null;
  faqs: FaqItem[];
};

// The single source of truth for which /[city]/[service] URLs exist, keyed `${locationKey}/${slug}`. Each
// entry has unique copy: shared template text gets pages de-indexed.
// Projects are framed as "typical" so nothing claims a specific customer, and local rules end with "we'll
// confirm what yours needs": we are not the permitting authority.
type PriorityContent = {
  intro: string[];
  projectExample: string;
  faqs: FaqItem[];
  /** Overrides the generic `<service> in <city>, IL. <service blurb>` default. */
  metaDescription?: string;
};

const cityServiceLocalContent: Record<string, PriorityContent> = {
  "springfield/concrete-driveways": {
    intro: [
      "Springfield driveways deal with real winters: repeated freeze-thaw cycles, snow shovels and plows, and de-icing salt tracked in all season. A driveway poured thin or on a poorly compacted base shows it fast, with cracks, heaved sections and a flaking surface. We pour and replace concrete driveways across Springfield, from older homes near the center of town to newer subdivisions on the west and south sides.",
      "Most driveways we replace failed from the bottom up. We break out the old slab, correct the base and the drainage, then pour a reinforced slab with control joints cut on proper spacing. Where you park heavier trucks, we pour thicker.",
    ],
    projectExample:
      "A typical Springfield driveway job is a two-car tear-out and re-pour. We remove and haul the old concrete, regrade and compact the base, set forms and reinforcement, then pour and broom-finish. Most take two to three days on site, weather permitting, plus about a week before you drive on it.",
    faqs: [
      {
        q: "How much does a concrete driveway cost in Springfield?",
        a: "It depends on size, removal of the old slab, access and finish. We measure, explain the options and send a free written quote, so you know the number before any work starts.",
      },
      {
        q: "Do I need a permit to replace a driveway in Springfield?",
        a: "Like-for-like replacement often doesn't, but widening a driveway or changing the apron at the street can need approval. We'll confirm what yours needs before we start.",
      },
      {
        q: "When is the pour season in Central Illinois?",
        a: "Most flatwork is poured from spring through late fall. We can pour in cooler weather with the right mix and curing protection, and we'll give you a realistic schedule instead of rushing a pour into a hard freeze.",
      },
    ],
  },
  "springfield/concrete-patios": {
    intro: [
      "A concrete patio turns an unused Springfield backyard into space you'll use from spring cookouts to fall evenings. We pour patios and walkways across Springfield in broom, smooth, exposed-aggregate and stamped finishes.",
      "Drainage and base prep decide how a patio holds up here. We grade the pad so water runs away from your foundation instead of pooling against it and freezing, and we cut control joints so any cracking happens where it's meant to.",
    ],
    projectExample:
      "A common Springfield patio is a 12x16 to 16x20 slab off the back door, sometimes with a short walkway to the driveway or a step down into the yard. Once the base is prepped, the pour and finish usually take one to two days.",
    faqs: [
      {
        q: "How big should my patio be?",
        a: "For a table and chairs plus a small seating area, many homeowners land around 16x20. We'll help you size it to your yard and how you plan to use it.",
      },
      {
        q: "Will a patio crack over an Illinois winter?",
        a: "All concrete moves. Proper base, drainage and control joints keep that movement from turning into random cracks across the middle of the slab.",
      },
      {
        q: "Should I seal my patio?",
        a: "A penetrating or film-forming sealer helps resist water and de-icing salt. We'll recommend one based on your finish and tell you how often to re-apply it.",
      },
    ],
  },
  "springfield/stamped-decorative-concrete": {
    intro: [
      "Stamped concrete gives a Springfield patio, walkway or front entry the look of stone, slate or brick for less than those materials cost to install. We pour, stamp, color and seal decorative concrete across Springfield.",
      "The sealer is what keeps stamped concrete looking good through Illinois winters, protecting the color and surface from water, freeze-thaw and salt. We seal every stamped job and add a non-slip additive on steps and walkways.",
    ],
    projectExample:
      "A typical Springfield stamped project is a back patio in an ashlar slate or seamless stone pattern with a contrasting border, poured and stamped in a day and sealed once it has cured.",
    faqs: [
      {
        q: "How often does stamped concrete need resealing?",
        a: "Plan on every two to three years, depending on sun, traffic and how much salt reaches it.",
      },
      {
        q: "Can I use de-icing salt on stamped concrete?",
        a: "We recommend avoiding rock salt on decorative concrete, especially in its first winter. Sand or a concrete-safe de-icer is easier on the surface and sealer.",
      },
    ],
  },
  "springfield/concrete-repair-resurfacing": {
    intro: [
      "Freeze-thaw cycles and salt are hard on concrete, and a lot of Springfield driveways, walks and steps show it as cracks, scaling and settled sections. Not all of it needs to be torn out. We repair and resurface concrete across Springfield when the slab underneath is still sound.",
      "We'll tell you plainly whether repair will hold or whether you're better off replacing. Paying for a repair that fails in two winters doesn't help anyone.",
    ],
    projectExample:
      "A typical Springfield repair job is a driveway or front walk with surface scaling and a few open cracks: we clean and fill the cracks, patch damaged areas, resurface and seal. Most are done in a day.",
    faqs: [
      {
        q: "Can you fix a sunken sidewalk section?",
        a: "Often, yes. Depending on the cause, we replace the section on a corrected base or address it with repair. We'll explain the options after we look at it.",
      },
      {
        q: "How long does resurfacing last?",
        a: "On a sound slab, with sealing and sensible de-icer use, resurfacing holds up for years. It won't fix a failed base, which is why we check that first.",
      },
    ],
  },
  "chatham/concrete-driveways": {
    intro: [
      "Chatham has a lot of newer homes, and many of the driveways we look at there are fifteen to twenty-five years old: poured on a base that was never fully compacted and now cracking along predictable lines. We pour and replace concrete driveways throughout Chatham.",
      "Fixing that means fixing the base, not just pouring new concrete on top of it. We find what caused the failure before we quote the replacement, and where an HOA has rules on finish or width, we build to what's approved.",
    ],
    projectExample:
      "A typical Chatham driveway job is a full tear-out and re-pour on a two-car drive: remove and haul, regrade and compact, reinforce, pour and broom-finish. Two to three days on site, weather permitting.",
    faqs: [
      {
        q: "Will you follow my HOA's driveway rules?",
        a: "Yes. If your subdivision has requirements on finish, color or widening, we build to what's approved and keep the site clean while we're there.",
      },
      {
        q: "How long before I can park on a new driveway?",
        a: "Stay off it on foot for about a day and keep vehicles off for roughly a week.",
      },
    ],
  },
  "rochester/concrete-patios": {
    intro: [
      "A concrete patio is the most cost-effective way to add outdoor living space to a Rochester home. We pour patios and connecting walkways across Rochester in broom, smooth, exposed-aggregate and stamped finishes.",
      "We set every patio with fall away from the house and cut joints on proper spacing, so water doesn't pond and freeze against your foundation.",
    ],
    projectExample:
      "A common Rochester patio is a 14x18 slab off the back of the house with a short walk to the driveway, poured and finished in one to two days once the base is ready.",
    faqs: [
      {
        q: "Concrete or pavers for a backyard patio?",
        a: "Concrete installs faster, costs less up front and is easy to maintain, and stamping gives you a decorative look. We'll walk you through the trade-offs for your yard.",
      },
      {
        q: "How soon can I use my new patio?",
        a: "You can usually walk on it after about 24 hours. Wait about a week before setting heavy furniture or a grill on it.",
      },
    ],
  },
};

// No template fallback: a pair without an entry has no page and next.config.ts 301s it.
export const cityServicePairs: { location: LocationKey; service: string }[] =
  Object.keys(cityServiceLocalContent).map((key) => {
    const [location, service] = key.split("/");
    return { location: location as LocationKey, service };
  });

const cityServicePairKeys = new Set(Object.keys(cityServiceLocalContent));

export function isCityServicePair(location: string, service: string): boolean {
  return cityServicePairKeys.has(`${location}/${service}`);
}

/** For cross-links, so a city page never links to a URL that redirects away. */
export function cityServicesFor(location: LocationKey): string[] {
  return cityServicePairs.filter((p) => p.location === location).map((p) => p.service);
}

export function getCityServiceContent(
  locationKey: LocationKey,
  slug: string,
): CityServiceContent | null {
  const service = getService(slug);
  const local = cityServiceLocalContent[`${locationKey}/${slug}`];
  if (!service || !local) return null;

  const location = locations[locationKey];
  const city = location.city;

  return {
    service,
    city,
    locationKey,
    neighborhoods: location.neighborhoods,
    metaTitle: `${service.name} in ${city}, IL`,
    metaDescription:
      local.metaDescription ??
      `${service.name} in ${city}, IL. ${service.blurb} Free written quotes from Springfield Concrete Group.`,
    heading: `${service.name} in ${city}, IL`,
    paragraphs: local.intro,
    projectExample: local.projectExample,
    faqs: local.faqs,
  };
}

// The city name is woven into each answer so location pages don't read as doorway pages.
export function getLocationFaqs(city: string): FaqItem[] {
  return [
    {
      q: `Do you offer free concrete estimates in ${city}?`,
      a: `Yes. Estimates in ${city} are free and in writing. For driveways and slabs we can often quote from satellite imagery and confirm the details on a short visit.`,
    },
    {
      q: `How soon can you start a concrete project in ${city}?`,
      a: `It depends on the season and our schedule. We'll give you a realistic start window up front, in writing with your quote.`,
    },
    {
      q: `What concrete services do you offer in ${city}?`,
      a: `Driveways, patios, walkways, slabs and pads, steps and stoops, repair and resurfacing, and stamped and decorative concrete for homes and small commercial properties in ${city}.`,
    },
    {
      q: `Is your concrete built for ${city}'s winters?`,
      a: `Yes. We use proper base prep, drainage and mix choices for Central Illinois freeze-thaw winters, and we cure and seal so the surface holds up to snow and salt in ${city}.`,
    },
  ];
}

export const quoteServiceOptions = [
  "Driveway",
  "Patio",
  "Walkway/Sidewalk",
  "Slab/Pad",
  "Steps/Stoop",
  "Repair/Resurfacing",
  "Stamped/Decorative",
  "Commercial",
  "Other",
];

export const trustImage = "/images/servicing-to-client-image.png";
export const clipboardImage = "/images/contractor_holding_pen+paper.png";

export type NavLink = { label: string; slug: string };

export const residentialNav: NavLink[] = [
  { label: "Concrete Driveways", slug: "concrete-driveways" },
  { label: "Patios & Walkways", slug: "concrete-patios" },
  { label: "Slabs & Pads", slug: "concrete-slabs-flatwork" },
  { label: "Steps & Stoops", slug: "steps-stoops-landings" },
  { label: "Repair & Resurfacing", slug: "concrete-repair-resurfacing" },
  { label: "Stamped & Decorative", slug: "stamped-decorative-concrete" },
  { label: "Walkways & Sidewalks", slug: "walkways-sidewalks" },
  { label: "Removal & Replacement", slug: "concrete-removal-replacement" },
];

export const commercialNav: NavLink[] = [
  { label: "Commercial Flatwork", slug: "commercial-flatwork" },
  { label: "Sidewalks & Walkways", slug: "commercial-sidewalks-walkways" },
  { label: "Parking Pads & Approach Slabs", slug: "commercial-parking-approach-slabs" },
  { label: "Repair & Resurfacing", slug: "commercial-concrete-repair-resurfacing" },
];
export const commercialServiceSlugs = new Set(commercialNav.map((item) => item.slug));

export type ProcessStep = { title: string; body: string };
export const processSteps: ProcessStep[] = [
  {
    title: "Request Your Free Quote",
    body: "Call, text or fill out the quick form and tell us about your project. It takes about a minute.",
  },
  {
    title: "We Measure and Explain",
    body: "A crew lead measures, walks you through the options and sends a written quote: scope, materials, price and timeline.",
  },
  {
    title: "Approve and Get Scheduled",
    body: "Once you approve the quote, we lock in a date and handle the job from prep to final walkthrough.",
  },
];

export type Stat = { value: string; label: string };
export const homeStats: Stat[] = [
  { value: "Free", label: "Written Quotes" },
  { value: "Local", label: "Springfield-Based" },
  { value: "Vetted", label: "Screened Crews" },
  { value: "One", label: "Accountable Company" },
];

export const aboutParagraphs: string[] = [
  "Springfield Concrete Group is a Springfield, Illinois concrete company focused on driveways, patios, walkways, slabs, steps and repairs. We pair homeowners and property owners with experienced, vetted concrete professionals and hold every project to one standard: proper prep, quality materials, clean finishing and clear communication from quote to final walkthrough.",
  "When you hire SCG, one company is accountable for your project. You get a written quote before work starts, a realistic timeline, and a crew that leaves your property tidy.",
];

// "Why SCG" blocks from the brand guide.
export const whyScg: { title: string; body: string }[] = [
  {
    title: "One accountable company",
    body: "Quoted, scheduled and backed by SCG from first call to final walkthrough.",
  },
  {
    title: "Vetted crews",
    body: "Every contractor is screened for experience, references, insurance and quality of work.",
  },
  {
    title: "Clear written quotes",
    body: "Scope, materials, price and timeline in writing before work starts.",
  },
  {
    title: "Built for Illinois weather",
    body: "Proper base prep, drainage and mix choices for freeze-thaw winters.",
  },
  {
    title: "Clean job sites",
    body: "We protect your property and leave it tidy.",
  },
];

export const valueProps = [
  "One Accountable Company",
  "Clear Written Quotes",
  "Clean Job Sites",
];

export type GalleryImage = { src: string; alt: string };

// Owner's own project photos. Flip to true to label the gallery as sample work.
// Excludes before/after pairs (comparison sliders) and the trust photo (About).
export const galleryIsSample = false;
export const galleryImages: GalleryImage[] = [
  { src: "/images/residential_driveway_concrete_2.png", alt: "Newly poured residential concrete driveway" },
  { src: "/images/workers_pouring_driveway_live_action.png", alt: "Crew pouring and finishing a concrete driveway" },
  { src: "/images/decorative_stamped_back_porch.png", alt: "Decorative stamped concrete back porch" },
  { src: "/images/decorative_stampted_back_patio.png", alt: "Decorative stamped concrete back patio" },
  { src: "/images/stamped_patio.png", alt: "Stamped concrete patio" },
  { src: "/images/stampted_patio_2.png", alt: "Stamped concrete patio detail" },
  { src: "/images/decorative_stamped_driveway.png", alt: "Stamped concrete driveway" },
  { src: "/images/front_walkway+driveway.png", alt: "Front walkway and driveway concrete work" },
  { src: "/images/walkway_concrete_front_of_house.png", alt: "Concrete walkway at a home's front entrance" },
  { src: "/images/commercial-entryway-clean.png", alt: "Commercial concrete entryway" },
  { src: "/images/commercial-sidewalk-entry-way-medical.png", alt: "Commercial sidewalk at a medical building" },
  { src: "/images/hoa_sidewalk_commercial.png", alt: "Community sidewalk concrete work" },
  { src: "/images/loadnig_dock_commercial.png", alt: "Commercial loading area concrete" },
  { src: "/images/driveway_close_up_detailed_8k.png", alt: "Broom-finished concrete driveway close-up" },
];

export const links = {
  call: phoneHref,
  text: textHref,
  quote: "#quote",
};

export type BeforeAfterPair = {
  before: string;
  after: string;
  label: string;
};

export type LocationContent = {
  key: LocationKey;
  city: string;
  title: string;
  seoTitle: string;
  description: string;
  heroImage: string;
  beforeAfterPairs: BeforeAfterPair[];
  neighborhoods: string[];
};

export const sharedBeforeAfter: BeforeAfterPair[] = [
  {
    before: "/images/before_driveway.png",
    after: "/images/after_driveway.png",
    label: "Driveway Replacement",
  },
  {
    before: "/images/back_patio_before.png",
    after: "/images/back_patio_after.png",
    label: "Backyard Patio",
  },
  {
    before: "/images/before_cracked_concrete_driveway.png",
    after: "/images/after_cracked_concrete_driveway.png",
    label: "Cracked Driveway Repair",
  },
];

export const locations: Record<LocationKey, LocationContent> = {
  springfield: {
    key: "springfield",
    city: "Springfield",
    title: "Concrete Contractor in Springfield, IL",
    seoTitle: "Concrete Springfield IL | Driveways, Patios & Repair",
    description:
      "Driveways, patios, walkways, slabs, steps and repairs for Springfield homeowners and property owners. Clear written quotes, vetted crews and one company accountable for the job.",
    heroImage: "/images/after_driveway.png",
    beforeAfterPairs: sharedBeforeAfter,
    neighborhoods: ["Leland Grove", "Jerome", "Enos Park", "Lake Springfield", "West Side"],
  },
  chatham: {
    key: "chatham",
    city: "Chatham",
    title: "Concrete Contractor in Chatham, IL",
    seoTitle: "Concrete Chatham IL | Driveways, Patios & Slabs",
    description:
      "New driveways, patios and slabs for Chatham homes, with base prep done right and finishes that fit your subdivision. Free written quotes.",
    heroImage: "/images/decorative_stampted_back_patio.png",
    beforeAfterPairs: sharedBeforeAfter,
    neighborhoods: ["Downtown Chatham", "North Chatham", "South Chatham", "Route 4 corridor"],
  },
  sherman: {
    key: "sherman",
    city: "Sherman",
    title: "Concrete Contractor in Sherman, IL",
    seoTitle: "Concrete Sherman IL | Driveways, Patios & Repair",
    description:
      "Concrete driveways, patios, walkways and repairs for Sherman homeowners just north of Springfield. Straight answers and a written price before work starts.",
    heroImage: "/images/workers_pouring_driveway_live_action.png",
    beforeAfterPairs: sharedBeforeAfter,
    neighborhoods: ["Village of Sherman", "Carpenter Park area", "I-55 corridor"],
  },
  rochester: {
    key: "rochester",
    city: "Rochester",
    title: "Concrete Contractor in Rochester, IL",
    seoTitle: "Concrete Rochester IL | Patios, Driveways & Slabs",
    description:
      "Patios, driveways, slabs and steps for Rochester homes east of Springfield. Proper drainage, clean finishes and a crew that leaves the site tidy.",
    heroImage: "/images/stamped_patio.png",
    beforeAfterPairs: sharedBeforeAfter,
    neighborhoods: ["Village of Rochester", "Route 29 corridor", "Rochester school district area"],
  },
  riverton: {
    key: "riverton",
    city: "Riverton",
    title: "Concrete Contractor in Riverton, IL",
    seoTitle: "Concrete Riverton IL | Driveways, Walkways & Repair",
    description:
      "Driveway replacement, walkways, steps and concrete repair for Riverton homeowners. Free written quotes and honest advice on repair versus replacement.",
    heroImage: "/images/front_walkway+driveway.png",
    beforeAfterPairs: sharedBeforeAfter,
    neighborhoods: ["Village of Riverton", "Sangamon River area", "I-72 corridor"],
  },
  jacksonville: {
    key: "jacksonville",
    city: "Jacksonville",
    title: "Concrete Contractor in Jacksonville, IL",
    seoTitle: "Concrete Jacksonville IL | Driveways, Patios & Slabs",
    description:
      "Concrete driveways, patios, slabs and commercial flatwork in Jacksonville. Clear scopes, written quotes and one company accountable from start to finish.",
    heroImage: "/images/residential_driveway_concrete_2.png",
    beforeAfterPairs: sharedBeforeAfter,
    neighborhoods: ["Downtown Jacksonville", "Lake Jacksonville area", "Morgan County"],
  },
  taylorville: {
    key: "taylorville",
    city: "Taylorville",
    title: "Concrete Contractor in Taylorville, IL",
    seoTitle: "Concrete Taylorville IL | Driveways, Patios & Repair",
    description:
      "Driveways, patios, steps and concrete repair for Taylorville homes and rentals. Built for Illinois winters and quoted clearly in writing.",
    heroImage: "/images/decorative_stamped_back_porch.png",
    beforeAfterPairs: sharedBeforeAfter,
    neighborhoods: ["Downtown Taylorville", "Lake Taylorville area", "Christian County"],
  },
  petersburg: {
    key: "petersburg",
    city: "Petersburg",
    title: "Concrete Contractor in Petersburg, IL",
    seoTitle: "Concrete Petersburg IL | Driveways, Walkways & Steps",
    description:
      "Concrete driveways, walkways, steps and patios for Petersburg homeowners. Proper prep, clean finishing and clear communication from quote to walkthrough.",
    heroImage: "/images/walkway_concrete_front_of_house.png",
    beforeAfterPairs: sharedBeforeAfter,
    neighborhoods: ["Downtown Petersburg", "Menard County", "New Salem area"],
  },
};

export type Testimonial = { name: string; city: string; quote: string };

// Real Google reviews only (brand rule: never fabricate). Review sections render nothing while this is empty.
// TODO: add real reviews as they come in.
export const testimonials: Testimonial[] = [];
