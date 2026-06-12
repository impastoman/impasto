# Stesura — recipe-sharing web files

These two files make the **Universal Links** recipe-sharing flow work
(task #41). Host them on **`stesura.perfectlyfinewares.com`** over HTTPS.
They are NOT part of the iOS app build — they live in the repo so they're
version-controlled and ready to deploy.

## 1. `apple-app-site-association` (AASA)

Tells iOS that the Stesura app owns links to this domain.

**Host at exactly:**
```
https://stesura.perfectlyfinewares.com/.well-known/apple-app-site-association
```

**Strict requirements (iOS will silently ignore the file otherwise):**
- Served over **HTTPS** with a valid certificate.
- **No file extension** (not `.json`).
- `Content-Type: application/json`.
- **No redirects** — must return 200 directly.
- Reachable without authentication.

The `appIDs` value is `<TeamID>.<BundleID>` = `24FCMTYXR8.com.stesura.app`
(already filled in). The `/import*` component matches the share links.

After deploying, verify with Apple's tool:
```
https://app-site-association.cdn-apple.com/a/v1/stesura.perfectlyfinewares.com
```

## 2. `import.html` — fallback page for `/import`

Shown to people **without** the app when they tap a share link (Safari
opens this page; if the app IS installed, iOS opens the app instead and
this page never loads). Route your host so `https://stesura.perfectlyfinewares.com/import`
serves this file.

**Before going live, fill in the App Store ID** (two spots, marked
`APP_STORE_ID`) — the numeric id from App Store Connect once Stesura is
registered (e.g. `6480001234`). Until then the button falls back to an
App Store search link and the Smart App Banner is inert.

## Still to do on the app side (Claude — task #41, once hosting is live)

- Add the **Associated Domains** capability: `applinks:stesura.perfectlyfinewares.com`.
- Switch recipe export from the `stesura://import?d=…` custom-scheme link
  to `https://stesura.perfectlyfinewares.com/import?d=…` (+ optional
  `&n=<recipe name>` so the fallback page can show the recipe name).
- Handle the incoming universal link (`.onOpenURL` / `.onContinueUserActivity`)
  and route it through the existing recipe-import decode.
