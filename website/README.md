# dancoworldwide.com

Marketing, support and privacy site for Ship Cap'n Crew, hosted on Cloudflare Pages from GitHub.

```
public/                    DanCo Worldwide home, shared styles/images, 404
public/ShipCapnCrew/       app landing page, support/, privacy/
functions/_middleware.js   www → apex, HTTP → HTTPS, legacy redirects, security headers
wrangler.jsonc             Pages config (build output: public/)
```

## Cloudflare Pages settings

| Setting | Value |
|---|---|
| Production branch | `master` |
| Framework preset | None |
| Build command | *(leave empty)* |
| Build output directory | `public` |
| Root directory | `website` |

Every push to `master` deploys. Add `dancoworldwide.com` and `www.dancoworldwide.com` under
the project's **Custom domains** tab.

## Develop

```sh
npm install
npm run dev        # http://localhost:8787, serves public/ with the middleware
```

## Redirects

| Path | Goes to |
|---|---|
| `/sccPP.html` (old App Store Support URL) | `/ShipCapnCrew/support/` |
| `/support`, `/privacy`, `/privacy-policy` | `/ShipCapnCrew/support/`, `/ShipCapnCrew/privacy/` |
| `/shipcapncrew/...` (any capitalization) | `/ShipCapnCrew/...` |
| `/app`, `/download` | App Store listing |
