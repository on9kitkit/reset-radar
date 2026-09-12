# Reset Radar

[![Build and test](https://github.com/on9kitkit/reset-radar/actions/workflows/ci.yml/badge.svg)](https://github.com/on9kitkit/reset-radar/actions/workflows/ci.yml)

A native macOS companion for coding-harness quotas and Codex surprise-reset news. Stack customisable mascots on your desktop, with the most important and largest mascot at the bottom. Click to expand available quotas, remaining percentages, routine reset times and banked reset credits. Drag to move without expanding.

Requires macOS 13 or later. Apple Silicon and Intel builds are included in the local build process. No third-party code dependencies.

## Build and check

Install Xcode with its command-line tools, then run from this folder:

```sh
python3 scripts/check-source.py
bash scripts/build.sh
python3 scripts/check-package.py
```

The build compiles both architectures with warnings treated as errors, runs offline regression tests, locally signs the app and writes `build/Reset Radar.zip` with a SHA-256 checksum. It does not read account credentials, call paid APIs, connect a harness, install the app or modify login items. Unzip the archive and move the app to your Applications folder to run it. Add it to macOS Login Items if you want automatic startup.

The signature is ad hoc. A public downloadable release still needs Developer ID signing and Apple notarization. See [the review record](CHECKS.md) for tested scope and remaining release checks.

## Automated checks

GitHub Actions runs on pushes to `main`, pull requests and manual dispatch. The `macOS build and offline tests` job uses the Intel macOS 15 runner with Xcode 16.4, compiles both architectures, runs the existing offline tests natively on Intel, checks source privacy and validates the extracted archive, license, checksum and signature. The workflow has read-only repository permission and a pinned checkout action. It receives no account keys or signing credentials and makes no paid API checks. Dependabot proposes weekly action updates.

Run the same commands above locally. The job summary records the exact commit and toolchain. These tests do not cover interactive desktop UI, live provider accounts, notarization or Intel user-interface behaviour.

## Customise and connect

Use the sliders button to change built-in mascot designs, colours, visibility and priority. Each higher mascot is 18% smaller. Customisation, Connections and Luna settings support scrolling and resizing; buttons show hover descriptions. Changes save automatically.

| Harness | Connection |
| --- | --- |
| Codex | Reads the signed-in local Codex account, including available limits and reset credits. A custom app/CLI location can be selected. |
| Claude Code | Installs a local status-line quota reader after you sign in inside Claude Code. |
| Antigravity CLI | Installs a local status-line quota reader; this does not connect the editor alone. |
| Cursor, Grok, Muse | Reads a compatible usage JSON file. Native sign-in and built-in exporters are not implemented. |

Missing quotas stay unavailable. Old reports are labelled stale. Built-in status-line setup preserves the existing command and unrelated settings; disconnect restores the previous status line where possible and keeps newer edits. Configure providers while their settings are not being edited elsewhere. Read the [connection guide](Resources/Connection%20Guide.html) for setup and the exporter format.

## Codex news

Only the Codex mascot changes colour:

- Green: a successful check found no current reset announcement.
- Yellow: news is ambiguous, indirect, unavailable or stale.
- Red: a current reset is confirmed by the news review with original X evidence.

Colours do not count down to routine resets. The app watches Tibo, `@thsottiaux`, through an indirect public ModelYard feed and optional OpenAI API news checks. Source links open the original X post. There is no guarantee of advance notice: providers may not announce a surprise reset, X access may fail, and model interpretation can be wrong.

Optional Luna checks use exactly `gpt-5.6-luna`. Enter your own OpenAI API key inside Luna settings; the key stays in macOS Keychain. Model availability depends on your API account. There is no automatic fallback if this model or web search is unavailable. The Codex app’s model list does not establish API access.

News checks and web searches are billed to your OpenAI API project. The default interval is 30 minutes, configurable to 60 or 120 minutes. The app allows at most 48 attempts per UTC day, up to two web-tool calls and 2,000 output tokens per request. Manual checks share the cap and a one-minute cooldown. These local caps are not a billing guarantee; set project spending controls in your OpenAI account as well.

Only public news queries, candidate titles and URLs go to OpenAI. Personal harness quotas stay local. API response storage is disabled in the request. A returned search citation alone cannot create a red state or announced countdown: the response must record opening the original allowed X post and classify the evidence as direct. This is a conservative model-assisted check, not independent proof of the post content or a refill on your own account. Cached news becomes uncertain after two hours. A confirmed completed reset remains relevant for 24 hours.

The Mac must be awake and the app running. Codex quotas refresh every minute, the indirect feed every five minutes and connected usage files every five seconds. No cloud monitor is included.

## Local data and sharing

Preferences belong to `local.resetradar.widget`. News and optional connection files live under `~/Library/Application Support/ResetRadar`. The OpenAI key belongs to the Keychain service `local.resetradar.openai`. Rebuilding or replacing this locally signed app may cause macOS to request Keychain access again; approve it yourself in the secure prompt.

This folder is the intended GitHub source root. It contains no runtime data, account files, API keys, personal launch agent, binaries or machine-specific paths. Build products are ignored. Review [SECURITY.md](SECURITY.md) before distributing a release.

## License

Copyright (c) 2026 on9kitkit. Licensed under the [MIT License](LICENSE). The license is also included in the app package.
