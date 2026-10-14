// Cloudflare Pages middleware for the Ship Cap'n Crew site.
// dancoworldwide.com is served by the router Worker in ../dancoworldwide, which proxies /ShipCapnCrew/*
// here and owns domain-wide concerns (www, HTTPS, legacy links). This only handles this app's paths.

const APP_PATH = "/ShipCapnCrew";

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

  // On shipcapncrew.pages.dev, the bare root goes to the app page.
  if (url.pathname === "/" || url.pathname === "/index.html") {
    return Response.redirect(new URL(`${APP_PATH}/`, url).toString(), 302);
  }

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
