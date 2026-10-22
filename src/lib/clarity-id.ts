// Public by nature (in every page's script tag). Set NEXT_PUBLIC_CLARITY_PROJECT_ID to switch Clarity on.
// Own module because clarity.tsx is "use client": a server import from it gets a reference, not the value.
export const CLARITY_PROJECT_ID = process.env.NEXT_PUBLIC_CLARITY_PROJECT_ID || "";
