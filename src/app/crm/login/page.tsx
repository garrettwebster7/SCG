import type { Metadata } from "next";
import Image from "next/image";

import { dict } from "@/lib/crm/i18n";
import { crmBase } from "@/lib/crm/nav";
import { LoginForm } from "./login-form";

export const metadata: Metadata = {
  title: { absolute: "CRM Login | Springfield Concrete Group" },
  robots: { index: false, follow: false },
};

// Same-site relative paths only, so this can't be an open redirect.
function safeNext(next: string | undefined): string | undefined {
  if (!next || !next.startsWith("/") || next.startsWith("//")) return undefined;
  return next;
}

export default async function CrmLoginPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string; lang?: string }>;
}) {
  const base = await crmBase();
  const sp = await searchParams;
  const next = safeNext(sp.next);
  const locale = "en" as const;
  const t = dict(locale);
  return (
    <main className="crm-auth">
      <div className="crm-auth-card">
        <Image src="/images/scg-logo-horizontal.png" alt="Springfield Concrete Group" width={715} height={138} className="crm-auth-logo" priority />
        <h1 className="crm-auth-title">{t.login.title}</h1>
        <p className="crm-auth-sub">{t.login.subtitle}</p>
        <LoginForm base={base} next={next} locale={locale} />
      </div>
    </main>
  );
}
