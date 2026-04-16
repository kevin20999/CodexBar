---
summary: "Packaging, signing, and bundled CLI notes for CodexTokenBar releases."
read_when:
  - Packaging/signing builds
  - Updating bundle layout or CLI bundling
---

# Packaging & signing

## Scripts
- `Scripts/package_app.sh`: builds host arch by default; set `ARCHES="arm64 x86_64"` for universal. Verifies slices, stages bundles under `.build/apps/`, and installs the main app to `/Applications/CodexTokenBar.app`. Uses `CODEXBAR_APP_NAME`, `CODEXBAR_APP_BUNDLE`, `CODEXBAR_EXECUTABLE_NAME`, and `CODEXBAR_BUNDLE_ID` to control the packaged app identity.
- `Scripts/compile_and_run.sh`: uses host arch; pass `--release-universal` or `--release-arches="arm64 x86_64"` for release packaging.
- `Scripts/sign-and-notarize.sh`: signs, notarizes, staples, and zips the release bundle as `CodexTokenBar-<version>.zip` by default (accepts `ARCHES` for universal). Use `CODEXBAR_SIGNING_IDENTITY` or `APP_IDENTITY` to point at your own Developer ID certificate.
- `Scripts/make_appcast.sh`: optional appcast helper. It generates release metadata and embedded HTML notes if you later wire Sparkle or another feed workflow back in. Set `CODEXBAR_APPCAST_FEED_URL` or `CODEXBAR_RELEASE_REPO` if the feed is not hosted on the current repo’s `origin`.
- `Scripts/changelog-to-html.sh`: converts the per-version changelog section to HTML for Sparkle.

## Bundle contents
- The current `TokenApp` release bundle is staged at `.build/apps/CodexTokenBar.app` and contains the main executable at `Contents/MacOS/CodexTokenBar` plus resources from `Sources/CodexBar/Resources`.
- SwiftPM resource bundles emitted next to the built product are copied into `Contents/Resources` when present.
- Legacy helper/widget/updater notes from the old `CodexBar` app no longer apply unless those targets are re-added to `Package.swift`.

## Releases
- Formal friend-distribution / release checklist lives in `docs/RELEASING.md`.

See also: `docs/sparkle.md`.
