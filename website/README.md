# Ship Cap'n Crew website

The Ship Cap'n Crew pages (landing, support, privacy) at `dancoworldwide.com/ShipCapnCrew/`, hosted on
Cloudflare Pages from GitHub. The domain itself is served by the router Worker in `../dancoworldwide`,
which passes `/ShipCapnCrew/*` through to this Pages project.

```
public/ShipCapnCrew/       landing page, support/, privacy/, styles, images, demo script
public/404.html            not-found page for missing /ShipCapnCrew/ paths
functions/_middleware.js   capitalization redirect, security headers
wrangler.jsonc             Pages config (build output: public/)
```

## Cloudflare Pages settings

| Setting | Value |
|---|---|
| Project name | `shipcapncrew` |
| Production branch | `master` |
| Framework preset | None |
| Build command | *(leave empty)* |
| Build output directory | `public` |
| Root directory | `website` |

Every push to `master` deploys. **Don't add a custom domain to this project**: `dancoworldwide.com` is attached
to the router Worker.

## Develop

```sh
npm install
npm run dev        # http://localhost:8787/ShipCapnCrew/
```
