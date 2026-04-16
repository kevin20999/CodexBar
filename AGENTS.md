# Repository Guidelines

## Project Structure & Modules
- `Sources/CodexBar`: Swift 6 menu bar app (usage/credits probes, icon renderer, settings). Keep changes small and reuse existing helpers.
- `Tests/CodexBarTests`: XCTest coverage for usage parsing, status probes, icon patterns; mirror new logic with focused tests.
- `Scripts`: build/package helpers (`package_app.sh`, `package_codexdaily.sh`, `sign-and-notarize.sh`, `make_appcast.sh`, `build_icon.sh`, `compile_and_run.sh`, `compile_and_run_codexdaily.sh`).
- `docs`: release notes and process (`docs/RELEASING.md`, screenshots). Root-level zips/appcast are generated artifacts—avoid editing except during releases.

## Build, Test, Run
- Dev loop: `./Scripts/compile_and_run.sh` kills old instances, runs `swift build` + `swift test`, packages, installs, relaunches `/Applications/CodexTokenBar.app`, and confirms it stays running.
- CodexDaily dev loop: `./Scripts/compile_and_run_codexdaily.sh` packages, installs, relaunches `/Applications/CodexDaily.app`, and does not touch `CodexTokenBar.app`.
- Quick build/test: `swift build` (debug) or `swift build -c release`; `swift test` for the full XCTest suite.
- Package locally: `./Scripts/package_app.sh` to refresh the staged bundle in `.build/apps/` and install `/Applications/CodexTokenBar.app`, then restart with `pkill -x CodexTokenBar || pkill -f CodexTokenBar.app || true; open -n /Applications/CodexTokenBar.app`.
- Package CodexDaily locally: `./Scripts/package_codexdaily.sh` to refresh `.build/apps/CodexDaily.app` and install `/Applications/CodexDaily.app` without packaging `CodexTokenBar.app`.
- Release flow: `./Scripts/sign-and-notarize.sh` (arm64 notarized zip) and `./Scripts/make_appcast.sh <zip> <feed-url>`; follow validation steps in `docs/RELEASING.md`.

## Coding Style & Naming
- Enforce SwiftFormat/SwiftLint: run `swiftformat Sources Tests` and `swiftlint --strict`. 4-space indent, 120-char lines, explicit `self` is intentional—do not remove.
- Favor small, typed structs/enums; maintain existing `MARK` organization. Use descriptive symbols; match current commit tone.

## Testing Guidelines
- Add/extend XCTest cases under `Tests/CodexBarTests/*Tests.swift` (`FeatureNameTests` with `test_caseDescription` methods).
- Always run `swift test` (or `./Scripts/compile_and_run.sh`) before handoff; add fixtures for new parsing/formatting scenarios.
- After any code change, run `pnpm check` and fix all reported format/lint issues before handoff.

## Commit & PR Guidelines
- Commit messages: short imperative clauses (e.g., “Improve usage probe”, “Fix icon dimming”); keep commits scoped.
- PRs/patches should list summary, commands run, screenshots/GIFs for UI changes, and linked issue/reference when relevant.

## Agent Notes
- Use the provided scripts and package manager (SwiftPM); avoid adding dependencies or tooling without confirmation.
- Validate behavior against the freshly installed bundle; restart via the pkill+open command above to avoid running stale binaries.
- To guarantee the right bundle is running after a rebuild, use: `pkill -x CodexTokenBar || pkill -f CodexTokenBar.app || true; open -n /Applications/CodexTokenBar.app`.
- After any code change that affects the app, always rebuild with `Scripts/package_app.sh` and restart the app using the command above before validating behavior.
- If you edited code, run `scripts/compile_and_run.sh` before handoff; it kills old instances, builds, tests, packages, relaunches, and verifies the app stays running.
- Per user request: after CodexDaily edits, rebuild and restart with `./Scripts/compile_and_run_codexdaily.sh`; after CodexTokenBar edits, use `./Scripts/compile_and_run.sh`.
- Release script: keep it in the foreground; do not background it—wait until it finishes.
- Release keys: find in `~/.profile` if missing (Sparkle + App Store Connect).
- Prefer modern SwiftUI/Observation macros: use `@Observable` models with `@State` ownership and `@Bindable` in views; avoid `ObservableObject`, `@ObservedObject`, and `@StateObject`.
- Favor modern macOS 15+ APIs over legacy/deprecated counterparts when refactoring (Observation, new display link APIs, updated menu item styling, etc.).
- Keep provider data siloed: when rendering usage or account info for a provider (Claude vs Codex), never display identity/plan fields sourced from a different provider.***
- Claude CLI status line is custom + user-configurable; never rely on it for usage parsing.
- Cookie imports: default Chrome-only when possible to avoid other browser prompts; override via browser list when needed.
