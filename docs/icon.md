---
summary: "Convert per-app macOS .icon bundles to .icns via Scripts/build_icon.sh and ictool."
read_when:
  - Updating the CodexBar app icon or asset pipeline
  - Preparing release builds that need a refreshed icns
---

# Icon pipeline (macOS .icon → .icns without Xcodebuild)

We keep separate glass `.icon` bundles for the two apps and convert them to app-specific `.icns` files via Xcode’s hidden CLI (`ictool`/`icontool`), without an Xcode project.

Current sources:
- `AppIcons/CodexTokenBar.icon`
- `AppIcons/CodexDailyBoard.icon`

Compatibility mirror:
- `Icon.icon` and `Icon.icns` continue to mirror the TokenBar icon so older local tooling still resolves a default icon.

## Script
Build both icons:
`Scripts/build_icon.sh`

Build one app icon by name:
`Scripts/build_icon.sh CodexTokenBar`
`Scripts/build_icon.sh CodexDailyBoard`

Legacy/manual mode:
`Scripts/build_icon.sh ICON.icon IconName [outdir] [outfile]`

What it does:
1) Finds `ictool` (or `icontool`) in `/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/`.
2) Renders the macOS Default appearance of the `.icon` to an 824×824 PNG (inner art, glass applied).
3) Pads to 1024×1024 with transparency (restores Tahoe squircle margin, avoids “white plate”).
4) Downscales to all required sizes into an `.iconset`.
5) Runs `iconutil -c icns` and writes an app-specific `.icns`.

Requirements:
- Xcode 26+ installed (IC tool lives inside the Xcode bundle).
- `sips` and `iconutil` (system tools).

Usage:
```bash
./Scripts/build_icon.sh
```
Outputs:
- `build/icon/CodexTokenBar/Icon.icns`
- `build/icon/CodexDailyBoard/Icon.icns`

And refreshes the TokenBar compatibility mirror at repo root:
- `Icon.icns`

Why this approach:
- Naive `sips`/`iconutil` from raw PNGs often leaves a white/grey plate because the inner art is full-bleed. The ictool render + transparent padding matches Xcode’s asset-pipeline output.

Notes:
- If Xcode is in a nonstandard location, set `XCODE_APP=/path/to/Xcode.app` before running.
- Script is CI-friendly; no Xcode project needed.
