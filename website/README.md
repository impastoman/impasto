# Stesura — recipe-sharing web files (Universal Links, task #41)

These files power the clean tap-to-open recipe sharing. They are hosted
**separately from the Squarespace marketing site** — Squarespace can't
serve Apple's AASA file (no `/.well-known/`, no extensionless files, no
`Content-Type` control). So they go on **Cloudflare Pages** at the
subdomain **`share.perfectlyfinewares.com`**.

(The marketing/landing + privacy pages stay on Squarespace at
`stesura.perfectlyfinewares.com` — untouched.)

## Files

| File | Served at | Purpose |
|------|-----------|---------|
| `.well-known/apple-app-site-association` | `/.well-known/apple-app-site-association` | Tells iOS the app owns links on this domain |
| `import.html` | `/import` | Fallback page for people without the app |
| `_headers` | (config) | Forces the AASA to `Content-Type: application/json` |
| `privacy.html` | (already on Squarespace) | Included for convenience; not required here |

The AASA's `appIDs` = `24FCMTYXR8.com.stesura.app` (Team ID + bundle ID).

## Cloudflare Pages setup (one-time)

1. **Create the project**
   - cloudflare.com → sign in → **Workers & Pages → Create → Pages**.
   - Either **Connect to Git** (point it at the `impasto` repo, set the
     build output / root directory to **`website`**, no build command),
     or **Upload assets** and drag the `website/` folder in.
   - Deploy. You'll get a `*.pages.dev` URL — confirm
     `https://<project>.pages.dev/.well-known/apple-app-site-association`
     returns the JSON.

2. **Add the custom subdomain**
   - In the Pages project → **Custom domains → Set up a custom domain** →
     enter `share.perfectlyfinewares.com`.
   - Cloudflare gives you a **CNAME target** (the `*.pages.dev` host).

3. **Point DNS (at your domain's DNS provider)**
   - Add a **CNAME** record: `share` → the `*.pages.dev` target Cloudflare
     showed. (If your DNS is already on Cloudflare, it offers to do this
     for you.)
   - Wait for it to go live (usually minutes) — HTTPS is automatic.

4. **Verify**
   - `https://share.perfectlyfinewares.com/.well-known/apple-app-site-association`
     → returns the JSON, and (in browser devtools) the response
     `Content-Type` is `application/json`.
   - `https://share.perfectlyfinewares.com/import` → shows the fallback page.
   - Apple's cache view:
     `https://app-site-association.cdn-apple.com/a/v1/share.perfectlyfinewares.com`

## App side (already wired by Claude — task #41)

- `StesuraExport.universalHost = "share.perfectlyfinewares.com"`.
- Export builds `https://share.perfectlyfinewares.com/import?d=…&n=…`.
- `StesuraApp` handles the link via `.onContinueUserActivity` /
  `.onOpenURL`.

**Remaining app step (in Xcode):** add the **Associated Domains**
capability → `applinks:share.perfectlyfinewares.com`
(Signing & Capabilities → + Capability). Then delete + reinstall so the
entitlement and domain association register.

## To fill in later

- `import.html` + `og:image`: set the real **App Store ID** (marked
  `APP_STORE_ID`) once Stesura is registered, and host a `share-card.png`
  (reuse the app icon, #39) for the Messages preview image.
