# CodexTokenBar

CodexTokenBar is a macOS menu bar app for tracking Codex / OpenAI quota, token usage, credits, and code review allowance at a glance.

> Fork notice
>
> CodexTokenBar is an independent fork of [CodexBar](https://github.com/steipete/CodexBar), the original project created by Peter Steinberger. This repository starts from the CodexBar codebase, keeps attribution to the upstream project, and is being reshaped into a narrower Codex / OpenAI-focused app. See [docs/fork-origin.md](docs/fork-origin.md) for attribution and scope details.

<img src="codexbar.png" alt="CodexTokenBar menu screenshot" width="520" />

## Focus of this fork

This fork is intentionally narrower than the original CodexBar project. The current direction is:

- Codex / OpenAI dashboard data first
- token, quota, credits, and code review visibility
- fork-specific branding, packaging, and release flow
- a simpler menu bar experience centered on one provider family

If you want the broader multi-provider app, use the original [CodexBar](https://github.com/steipete/CodexBar).

## What it shows

- Remaining quota windows and reset times
- Code review allowance
- Credits balance
- Usage breakdown and recent history
- OpenAI account snapshot details when available

## Privacy

- Browser cookie import is opt-in.
- Dashboard parsing and cache handling stay local to the app.
- No passwords are stored in the repository.

## Install

This fork does not yet publish its own release channel or Homebrew metadata. Until that is set up, build from source.

## Build from source

```bash
swift build -c release
./Scripts/package_app.sh
open -n /Applications/CodexTokenBar.app
```

Dev loop:

```bash
./Scripts/compile_and_run.sh
```

CodexDaily-only dev loop:

```bash
./Scripts/compile_and_run_codexdaily.sh
```

Clean local caches and generated artifacts:

```bash
./Scripts/clean_local_artifacts.sh
```

This removes local-only directories such as `.build`, `.tmp-modulecache`, `.artifacts`, `.upstream`, and generated `.app` bundles. They are safe to recreate when you build again. If you prefer package scripts, `npm run clean:local` calls the same command.

## Docs

- [Fork origin and attribution](docs/fork-origin.md)
- [Architecture](docs/architecture.md)
- [CLI reference](docs/cli.md)
- [Provider authoring](docs/provider.md)

## Original project

- Original repository: [steipete/CodexBar](https://github.com/steipete/CodexBar)
- Original author: Peter Steinberger
- Original license: MIT
- Upstream project scope: broader multi-provider menu bar tracking across Codex, Claude, Cursor, Gemini, and other providers

## Credits

CodexTokenBar is based on CodexBar. The original concept, architecture, and much of the foundation come from Peter Steinberger's [CodexBar](https://github.com/steipete/CodexBar). Fork-specific changes in this repository focus on Codex / OpenAI token workflows, branding, and packaging.

## License

MIT. Keep the original license text and attribution intact when redistributing or creating further forks.
