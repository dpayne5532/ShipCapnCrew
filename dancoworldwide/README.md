# dancoworldwide.com router

A Cloudflare Worker that owns `dancoworldwide.com`. It serves the DanCo Worldwide hub page and passes
each app's path through to that app's own Cloudflare Pages project, so every app's site deploys from its own repo.

| Path | Served by |
|---|---|
| `/` | Hub page (`public/`) |
| `/ShipCapnCrew/*` | `shipcapncrew.pages.dev` (this repo, `website/`) |
| `/fiveDiceTV/*` | `fivedicetv.pages.dev` (fiveDiceTV repo, `website/`) |
| `/sccPP.html` (old App Store Support URL) | redirect to `/ShipCapnCrew/support/` |
| Other capitalizations (`/shipcapncrew/`, `/FiveDiceTV/`) | redirect to the canonical path |

The router also redirects `www` and plain HTTP to `https://dancoworldwide.com`, and adds
security headers (a strict CSP on the hub's own pages; apps set their own CSP).

## Adding an app

1. Make sure the app's Pages project serves its files under the same path, e.g. `myapp.pages.dev/MyApp/`.
2. Add `{ path: "/MyApp", originVar: "MYAPP_ORIGIN" }` to `APPS` in `src/index.js`.
3. Add `"MYAPP_ORIGIN": "https://myapp.pages.dev"` to `vars` in `wrangler.jsonc`.
4. Add a card to `public/index.html` and the URLs to `public/sitemap.xml`.

## Develop

```sh
npm install
npm run dev   # http://localhost:8790
```

`npm run dev` expects both app sites running locally, each with its own inspector port so they don't collide:

```sh
cd ../website && npx wrangler pages dev --port 8791 --inspector-port 9331
npx wrangler pages dev <fiveDiceTV repo>/website/public --port 8792 --inspector-port 9332
```

## Deploy

```sh
npx wrangler login   # once
npm run deploy
```

The custom domains `dancoworldwide.com` and `www.dancoworldwide.com` are declared in `wrangler.jsonc` and attach
to this Worker on deploy. Don't also add them to either Pages project.
