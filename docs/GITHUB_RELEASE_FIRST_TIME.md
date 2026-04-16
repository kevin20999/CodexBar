---
summary: "First-time GitHub Release checklist for CodexTokenBar without Sparkle."
read_when:
  - Preparing the first public GitHub Release for CodexTokenBar
  - Setting up release credentials for the first time
  - Publishing a notarized CodexTokenBar zip without Sparkle
---

# GitHub Release first-time checklist (CodexTokenBar)

This checklist is the **first-time path** for publishing `CodexTokenBar` to GitHub Releases.

It is intentionally narrower than [`docs/RELEASING.md`](./RELEASING.md):

- publish **CodexTokenBar only**
- ship a **Developer ID signed + notarized zip**
- use **your own fork** as the release repo
- **do not** require Sparkle/appcast in this phase

Use this file if this is your first internet-facing release.

## Current snapshot and blockers

Use this checklist to verify the machine is release-ready before the first public GitHub Release.

Before continuing, confirm these prerequisites:

- `Developer ID Application` certificate is installed
- `gh` CLI is installed and logged in
- local `origin` points to your personal fork
- `APP_STORE_CONNECT_API_KEY_P8`, `APP_STORE_CONNECT_KEY_ID`, and `APP_STORE_CONNECT_ISSUER_ID` are available in the release shell
- `Scripts/sign-and-notarize.sh` is Sparkle-independent and only requires `APP_STORE_CONNECT_*`

## Phase 0: fix the release script first

Goal: confirm `Scripts/sign-and-notarize.sh` stays usable for GitHub Release-only publishing.

- [x] `Scripts/sign-and-notarize.sh` no longer requires `SPARKLE_PRIVATE_KEY_FILE`
- [x] `APP_STORE_CONNECT_*` remain the only required release credentials for notarization
- [x] Sparkle requirements stay only in:
  - `Scripts/make_appcast.sh`
  - `Scripts/verify_appcast.sh`
  - any later Sparkle-specific release path
- [x] Dry-run validation confirms the script now fails on missing `APP_STORE_CONNECT_*`, not Sparkle

Done when:

- you can explain the split clearly:
  - `sign-and-notarize.sh` = formal GitHub Release artifact
  - `make_appcast.sh` = optional later Sparkle step

## Phase 1: prepare GitHub Release dependencies

Goal: make this machine capable of creating and publishing a release to **your fork**.

### 1.1 Create or confirm your GitHub fork

- [ ] Open the upstream repo in the browser
- [ ] Click `Fork`
- [ ] Confirm the fork exists under your own GitHub account

Done when:

- your fork URL is real and reachable, for example:
  - `https://github.com/<your-account>/CodexBar`

### 1.2 Point local git at your fork

Recommended model:

- `upstream` = original repo
- `origin` = your fork

Commands:

```bash
cd /Users/kevin/codexbardiy
git remote rename origin upstream
git remote add origin https://github.com/<your-account>/CodexBar.git
git remote -v
```

- [ ] `origin` now points to your fork
- [ ] `upstream` points to `steipete/CodexBar`

Done when:

- `git remote -v` shows your fork as `origin`

### 1.3 Install GitHub CLI

Recommended:

```bash
brew install gh
```

Then authenticate:

```bash
gh auth login
gh auth status
```

- [ ] `gh` is installed
- [ ] `gh auth status` succeeds

Done when:

- you can create releases from this machine without browser copy-paste workarounds

### 1.4 Create App Store Connect API key

Open:

- [App Store Connect](https://appstoreconnect.apple.com/)
- `Users and Access`
- `Integrations`
- `App Store Connect API`
- `Team Keys`
- `Generate API Key`

Collect these values:

- [ ] `AuthKey_XXXXXX.p8`
- [ ] `Key ID`
- [ ] `Issuer ID`

Store the `.p8` file in a path you control, for example:

- `~/Documents/release-keys/AuthKey_XXXXXX.p8`

Done when:

- you know the exact file path for the `.p8`
- you have the matching `Key ID`
- you have the matching `Issuer ID`

### 1.5 Export notarization credentials

Recommended shell setup:

```bash
export APP_STORE_CONNECT_API_KEY_P8="$(cat /path/to/AuthKey_XXXXXX.p8)"
export APP_STORE_CONNECT_KEY_ID="YOUR_KEY_ID"
export APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"
```

Verify:

```bash
printf 'APP_STORE_CONNECT_API_KEY_P8=%s\nAPP_STORE_CONNECT_KEY_ID=%s\nAPP_STORE_CONNECT_ISSUER_ID=%s\n' \
"${APP_STORE_CONNECT_API_KEY_P8:+set}" \
"${APP_STORE_CONNECT_KEY_ID:+set}" \
"${APP_STORE_CONNECT_ISSUER_ID:+set}"
```

- [ ] all three values show as present

Done when:

- notarization credentials are available in the terminal session you will use for release

## Phase 2: create and validate the formal release artifact

Goal: produce a notarized `CodexTokenBar` zip and validate it locally.

### 2.1 Prepare release metadata

- [ ] confirm `version.env` has the target `MARKETING_VERSION`
- [ ] finalize the matching `CHANGELOG.md` entry
- [ ] make sure you are releasing **CodexTokenBar only**

### 2.2 Run the formal packaging flow

Command:

```bash
cd /Users/kevin/codexbardiy
CODEXBAR_PACKAGE_DAILY_APP=0 ./Scripts/sign-and-notarize.sh
```

Expected outputs:

- [ ] `CodexTokenBar-<version>.zip`
- [ ] `CodexTokenBar-<version>.dSYM.zip`

### 2.3 Validate the packaged app

Use `ditto`, not `unzip`:

```bash
mkdir -p /tmp/codextokenbar-release-check
rm -rf /tmp/codextokenbar-release-check/CodexTokenBar.app
ditto -x -k CodexTokenBar-<version>.zip /tmp/codextokenbar-release-check
spctl -a -t exec -vv /tmp/codextokenbar-release-check/CodexTokenBar.app
stapler validate /tmp/codextokenbar-release-check/CodexTokenBar.app
```

- [ ] `spctl` passes
- [ ] `stapler validate` passes
- [ ] extracted app launches locally

Done when:

- you have a notarized zip that works without Sparkle/appcast

## Phase 3: publish GitHub Release

Goal: make the notarized build downloadable from your fork.

### 3.1 Push code and tag

```bash
cd /Users/kevin/codexbardiy
git push origin <your-branch>
git tag v<version>
git push origin v<version>
```

- [ ] branch is on your fork
- [ ] tag `v<version>` exists on your fork

### 3.2 Create the GitHub Release

Recommended:

```bash
gh release create v<version> \
  CodexTokenBar-<version>.zip \
  CodexTokenBar-<version>.dSYM.zip \
  --repo <your-account>/CodexBar \
  --title "CodexTokenBar <version>" \
  --notes-file /path/to/release-notes.md
```

Notes:

- release notes should come from the matching changelog section
- do not upload friend/ad hoc zips here

- [ ] release is published on your fork
- [ ] both zip and dSYM are attached

Done when:

- the GitHub Release page exists and the assets are downloadable

## Phase 4: post-release verification

Goal: prove the public release really works.

### 4.1 Check the public download

- [ ] open the GitHub Release page in the browser
- [ ] click the uploaded `CodexTokenBar-<version>.zip`
- [ ] confirm the download starts from your fork, not upstream

Optional header check:

```bash
curl -I -L "https://github.com/<your-account>/CodexBar/releases/download/v<version>/CodexTokenBar-<version>.zip"
```

### 4.2 Validate the public artifact

- [ ] download the release asset fresh
- [ ] extract with `ditto -x -k`
- [ ] open the app
- [ ] confirm `CodexDaily.app` is not part of the release

Done when:

- a clean public download from GitHub Release installs and launches successfully

## Not in scope for this first release

Do **not** block this first GitHub Release on:

- Sparkle private key
- `appcast.xml`
- `generate_appcast`
- `sign_update`
- automatic updates
- official website downloads

Those can be added in a later phase after the first formal GitHub Release is working.
