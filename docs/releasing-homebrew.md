---
summary: "Homebrew Cask release steps for CodexTokenBar (Sparkle-disabled builds)."
read_when:
  - Publishing a CodexTokenBar release via Homebrew
  - Updating the Homebrew tap cask definition
---

# CodexTokenBar Homebrew Release Playbook

Homebrew is for the UI app via Cask. Homebrew installs should be updated via `brew`; do not assume a separate in-app updater is present in the current `TokenApp` bundle.

## Prereqs
- Homebrew installed.
- Access to the tap repo: `../homebrew-tap`.

## 1) Release CodexTokenBar normally
Follow `docs/RELEASING.md` to publish `CodexTokenBar-<version>.zip` to GitHub Releases.

## 2) Update the Homebrew tap cask
In `../homebrew-tap`, add/update the cask at `Casks/codexbar.rb`:
- `url` points at the GitHub release asset: `.../releases/download/v<version>/CodexTokenBar-<version>.zip`
- Update `sha256` to match that zip.
- Keep `depends_on arch: :arm64` and `depends_on macos: ">= :sonoma"` (CodexTokenBar is macOS 14+).

## 2b) Update the Homebrew tap formula (Linux CLI)
In `../homebrew-tap`, add/update the formula at `Formula/codexbar.rb`:
- `url` points at the GitHub release assets:
  - `.../releases/download/v<version>/CodexBarCLI-v<version>-linux-aarch64.tar.gz`
  - `.../releases/download/v<version>/CodexBarCLI-v<version>-linux-x86_64.tar.gz`
- Update both `sha256` values to match those tarballs.

## 3) Verify install
```sh
brew uninstall --cask codexbar || true
brew untap steipete/tap || true
brew tap steipete/tap
brew install --cask steipete/tap/codexbar
open -a CodexTokenBar
```

## 4) Push tap changes
Commit + push in the tap repo.
