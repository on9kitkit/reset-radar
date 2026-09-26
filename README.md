# Reset Radar

[![Build and test](https://github.com/on9kitkit/reset-radar/actions/workflows/ci.yml/badge.svg)](https://github.com/on9kitkit/reset-radar/actions/workflows/ci.yml)

A native macOS companion for coding-harness quotas and Codex surprise-reset news. Stack customisable mascots on your desktop, with the most important and largest mascot at the bottom. Click to expand available quotas, remaining percentages, routine reset times and banked reset credits. Drag to move without expanding.

![Reset Radar illustration: a mint robot supports a smaller peach sun and an even smaller lilac cat, showing the highest-priority mascot at the bottom.](docs/images/hero-stack.png)

*Product illustration. The largest mascot at the bottom is your highest-priority harness.*

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

![Six built-in mascot designs in vibrant colours: Robot, Sun, Comet, Orbit, Cat and Pointer.](docs/images/mascot-gallery.png)

*Illustrated gallery of the built-in designs. Each harness can use any mascot; other providers keep a fixed colour.*

Use the sliders button to change built-in mascot designs, colours, visibility and priority. Each higher mascot is 18% smaller. Customisation, Connections and Luna settings support scrolling and resizing; buttons show hover descriptions. Changes save automatically.

| Harness | Connection |
| --- | --- |
| Codex | Automatically finds the Codex CLI bundled in Codex or ChatGPT, or a standalone installation. Reads your existing signed-in account, available limits and reset credits. |
| Claude Code | Installs a local status-line quota reader after you sign in inside Claude Code. |
| Antigravity CLI | Installs a local status-line quota reader; this does not connect the editor alone. |
| Cursor, Grok, Muse | Reads a compatible usage JSON file. Native sign-in and built-in exporters are not implemented. |

For Codex, start with **Connect account**; sign in or switch accounts inside Codex itself. **Connection options → Find Codex again** repairs a moved or changed installation. The screen shows the detected app and last quota report. Claude and Antigravity offer **Reconnect usage** to repair their local readers.

Missing quotas stay unavailable. Old reports are labelled stale. Built-in status-line setup preserves the existing command and unrelated settings; disconnect restores the previous status line where possible and keeps newer edits. Configure providers while their settings are not being edited elsewhere. Read the [connection guide](Resources/Connection%20Guide.html) for setup and the exporter format.

## Codex news

![Codex news colours: mint green means no current reset announcement found, yellow includes reported resets awaiting verification or stale news, and coral red means the original announcement was directly verified. These are news states, not routine reset countdowns.](docs/images/codex-news-colours.png)

Only the Codex mascot changes colour:

- Green: a successful check found no current reset announcement.
- Yellow: a reset is reported but its original post has not been verified, or news is unclear, unavailable or stale.
- Red: the news review directly verified a current explicit reset announcement with original X evidence.

Colours do not count down to routine resets. The optional OpenAI news check watches `@thsottiaux`, `@reach_vb`, `@OpenAI` and `@OpenAIDevs`. The public ModelYard feed remains an indirect source for Tibo’s posts. There is no guarantee of advance notice: providers may not announce a surprise reset, X access may fail, and model interpretation can be wrong.

The news card separates the reported claim from its verification. **Reset reported** means the review found an explicit reset claim in search results or a public mirror, including a fresh discovery-feed candidate supplied to that same review. **Original unavailable** means the original X post could not be read; **Original not verified** means the claim is still indirect. These reports keep their headline and source links, so a yellow card can contain useful reset news. An access block such as X HTTP 403 does not become direct verification. Only direct verification can turn the mascot red or add an announced reset time to its countdown. Public news never proves that your own account refilled.

To keep hourly monitoring, open **Luna API settings…** from the menu-bar paw, leave your saved OpenAI API key in place, select **Check every → 1 hour**, enable **Enable scheduled Luna checks**, then choose **Check news now** for an immediate review. If no key is saved, enter your OpenAI key in the secure field and choose **Save key & start Luna**. No X login, X API key or new credential is required to display reported reset news. Direct verification still depends on whether the original content is accessible to the news check; this release has no authenticated X API integration.

Optional Luna checks use exactly `gpt-6-luna`. Enter your own OpenAI API key inside Luna settings; the key stays in macOS Keychain. Model availability depends on your API account. There is no automatic fallback if this model or web search is unavailable. The Codex app’s model list does not establish API access. News settings show the model returned by the last API response, when supplied.

News checks and web searches are billed to your OpenAI API project. The default interval is 30 minutes, configurable to 60 or 120 minutes. The app allows at most 48 attempts per UTC day, up to six web-tool calls and 3,000 output tokens per request. Manual checks share the cap and a one-minute cooldown. These local caps are not a billing guarantee; set project spending controls in your OpenAI account as well.

Only public news queries, candidate titles and URLs go to OpenAI. Personal harness quotas stay local. API response storage is disabled in the request. A returned search citation alone cannot create a red state or announced countdown: the response must record opening the original allowed X post and classify the evidence as direct. This is a conservative model-assisted check, not independent proof of the post content. The card keeps reported news separate from unavailable verification, a failed check, paused monitoring, a missing API key or stale news. A successful no-announcement result requires a completed search with a recorded source from a monitored account. Cached reviews are marked stale after two hours. A directly verified completed reset is considered current news for 24 hours, but its review must still be fresh to turn the mascot red.

The Mac must be awake and the app running. Codex quotas refresh every minute, the indirect feed every five minutes and connected usage files every five seconds. No cloud monitor is included.

## Local data and sharing

Preferences belong to `local.resetradar.widget`. News and optional connection files live under `~/Library/Application Support/ResetRadar`. The OpenAI key belongs to the Keychain service `local.resetradar.openai`. Rebuilding or replacing this locally signed app may cause macOS to request Keychain access again; approve it yourself in the secure prompt.

This folder is the intended GitHub source root. It contains no runtime data, account files, API keys, personal launch agent, binaries or machine-specific paths. Build products are ignored. Review [SECURITY.md](SECURITY.md) before distributing a release.

## License

Copyright (c) 2026 on9kitkit. Licensed under the [MIT License](LICENSE). The license is also included in the app package.
