---
summary: "Sparkle integration details for CodexTokenBar: updater config, keys, and release flow."
read_when:
  - Touching Sparkle settings, feed URL, or keys
  - Generating or troubleshooting the Sparkle appcast
  - Validating update toggles or updater UI
---

# Sparkle integration

The current `TokenApp` release bundle does not embed Sparkle by default. Keep this doc only for the optional appcast/update-feed workflow or if Sparkle integration is reintroduced later.

- `Scripts/make_appcast.sh` still supports generating appcast entries and HTML release notes for `CodexTokenBar-<ver>.zip`.
- If Sparkle is reintroduced, update the bundled `Info.plist` fields (`SUFeedURL`, `SUPublicEDKey`) in `Scripts/package_app.sh` and re-document the runtime updater surface before shipping it.

## Release flow
1) Build & notarize as usual (`./Scripts/sign-and-notarize.sh`), producing notarized `CodexTokenBar-<ver>.zip`.
2) Generate appcast entry with Sparkle `generate_appcast` using the Ed25519 private key; HTML release notes come from `CHANGELOG.md` via `Scripts/changelog-to-html.sh`. For beta releases: set `SPARKLE_CHANNEL=beta` to tag the entry. If the feed is not on the current `origin` repo, set `CODEXBAR_APPCAST_FEED_URL` or `CODEXBAR_RELEASE_REPO`.
3) Upload `appcast.xml` + zip to GitHub Releases (feed URL stays stable).
4) Tag/release.

## Notes
- HTML release notes are embedded in the appcast entry and can still be hosted alongside the release zip even if the app bundle itself is currently standalone.
- If you reintroduce a bundled updater, update `Info.plist` (`SUFeedURL`, `SUPublicEDKey`) and the release checklist before shipping it.
- Homebrew installs should continue to be updated via `brew`.
