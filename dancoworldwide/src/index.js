// Router for dancoworldwide.com. Serves the DanCo hub (public/) and passes each app's
// path through to that app's own Cloudflare Pages project, so every app deploys from its own repo.

// Canonical path → Pages origin (the origin serves its files under the same path).
// Origins come from wrangler.jsonc vars so local dev can point them at `wrangler pages dev`.
const APPS = [
  { path: "/ShipCapnCrew", originVar: "SHIPCAPNCREW_ORIGIN" },
  { path: "/fiveDiceTV", originVar: "FIVEDICETV_ORIGIN" },
];

// Old URLs that App Store Connect may still link to. Keys are lowercase.
const REDIRECTS = {
  "/sccpp.html": "/ShipCapnCrew/support/",
};

const BASE_HEADERS = {
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "X-Content-Type-Options": "nosniff",
  "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
};

// The hub's own pages only load first-party files. Apps set their own CSP.
const HUB_HEADERS = {
  ...BASE_HEADERS,
  "Content-Security-Policy":
    "default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; " +
    "base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=(), interest-cohort=()",
};

function withHeaders(response, extra) {
  const out = new Response(response.body, response);
  for (const [name, value] of Object.entries(extra)) {
    if (!out.headers.has(name)) out.headers.set(name, value);
  }
  return out;
}

async function proxy(request, url, origin) {
  const target = new URL(url.pathname + url.search, origin);
  const response = await fetch(new Request(target, request), { redirect: "manual" });

  // Keep the visitor on dancoworldwide.com when the origin redirects (e.g. adding a trailing slash).
  const location = response.headers.get("Location");
  if (location) {
    const resolved = new URL(location, target);
    if (resolved.origin === new URL(origin).origin) {
      const out = new Response(response.body, response);
      out.headers.set("Location", resolved.pathname + resolved.search);
      return withHeaders(out, BASE_HEADERS);
    }
  }
  return withHeaders(response, BASE_HEADERS);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Canonical host + HTTPS on the real domain. `npm run dev` sets CANONICAL_REDIRECTS=off because
    // wrangler dev presents requests as plain-HTTP requests to the production host, which would loop.
    if (env.CANONICAL_REDIRECTS !== "off" && url.hostname.endsWith("dancoworldwide.com")) {
      let changed = false;
      if (url.hostname.startsWith("www.")) {
        url.hostname = url.hostname.slice(4);
        changed = true;
      }
      if (url.protocol === "http:") {
        url.protocol = "https:";
        changed = true;
      }
      if (changed) return Response.redirect(url.toString(), 301);
    }

    const lower = url.pathname.toLowerCase();
    const target = REDIRECTS[lower];
    if (target) return Response.redirect(new URL(target, url).toString(), 301);

    for (const app of APPS) {
      const prefix = app.path.toLowerCase();
      if (lower !== prefix && !lower.startsWith(prefix + "/")) continue;
      // Paths are case-sensitive on the origin: send /shipcapncrew/... to /ShipCapnCrew/...
      if (!url.pathname.startsWith(app.path)) {
        url.pathname = app.path + url.pathname.slice(app.path.length);
        return Response.redirect(url.toString(), 301);
      }
      return proxy(request, url, env[app.originVar]);
    }

    return withHeaders(await env.ASSETS.fetch(request), HUB_HEADERS);
  },
};
