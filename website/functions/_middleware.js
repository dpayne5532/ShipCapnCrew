// Cloudflare Pages middleware: runs before every request to the static site.
// Canonical host, HTTPS, legacy App Store links, and security headers.

const APP_STORE = "https://apps.apple.com/us/app/ship-capn-crew/id1670235470";

const APP_PATH = "/ShipCapnCrew";

// Old or shorthand URLs that App Store Connect (or anyone else) may link to.
// Keys are lowercase; matching is case-insensitive.
const REDIRECTS = {
  "/sccpp.html": `${APP_PATH}/support/`,
  "/support": `${APP_PATH}/support/`,
  "/support/": `${APP_PATH}/support/`,
  "/privacy": `${APP_PATH}/privacy/`,
  "/privacy/": `${APP_PATH}/privacy/`,
  "/privacy-policy": `${APP_PATH}/privacy/`,
  "/app": APP_STORE,
  "/download": APP_STORE,
};

const SECURITY_HEADERS = {
  "Content-Security-Policy":
    "default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; " +
    "base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "X-Content-Type-Options": "nosniff",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=(), interest-cohort=()",
  "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
};

export async function onRequest({ request, next }) {
  const url = new URL(request.url);

  // Only enforce the canonical host in production, not on localhost or *.pages.dev previews.
  if (url.hostname.endsWith("dancoworldwide.com")) {
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

  const target = REDIRECTS[url.pathname.toLowerCase()];
  if (target) return Response.redirect(new URL(target, url).toString(), 301);

  // Asset paths are case-sensitive: send /shipcapncrew/... to /ShipCapnCrew/...
  const lower = url.pathname.toLowerCase();
  const appLower = APP_PATH.toLowerCase();
  if ((lower === appLower || lower.startsWith(appLower + "/")) && !url.pathname.startsWith(APP_PATH)) {
    url.pathname = APP_PATH + url.pathname.slice(APP_PATH.length);
    return Response.redirect(url.toString(), 301);
  }

  const response = await next();
  const headers = new Headers(response.headers);
  for (const [name, value] of Object.entries(SECURITY_HEADERS)) headers.set(name, value);
  if (/\.(jpg|png|svg|webp)$/.test(url.pathname)) {
    headers.set("Cache-Control", "public, max-age=604800");
  }
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}
