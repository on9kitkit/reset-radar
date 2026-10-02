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

Use the sliders button to change built-in mascot designs, colours, visibility and priority. Each higher mascot is 18% smaller. Customisation, Connections and News settings support scrolling and resizing; buttons show hover descriptions. Changes save automatically.

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

Colours do not count down to routine resets. The optional news check watches `@thsottiaux`, `@reach_vb`, `@OpenAI` and `@OpenAIDevs`. The public ModelYard feed remains an indirect source for Tibo’s posts. There is no guarantee of advance notice: providers may not announce a surprise reset, X access may fail, and model interpretation can be wrong.

The news card separates the reported claim from its verification. **Reset reported** means the review found an explicit reset claim in search results or a public mirror, including a fresh discovery-feed candidate supplied to that same review. **Original unavailable** means the original X post could not be read; **Original not verified** means the claim is still indirect. These reports keep their headline and source links, so a yellow card can contain useful reset news. An access block such as X HTTP 403 does not become direct verification. Only direct verification can turn the mascot red or add an announced reset time to its countdown. Public news never proves that your own account refilled.

### Direct X connection

For authenticated original-post access, open **News settings… → X API + Codex plan · direct posts**. This connects directly to X instead of relying on a web-search service to open x.com.

1. Sign in to [X Developer Console](https://console.x.com), create an app and obtain its **Bearer Token**. No X password, API secret or user access-token pair is needed.
2. Review [X pricing](https://docs.x.com/x-api/getting-started/pricing), add credits if required and set a spending limit in the console. Leave automatic recharge off unless you deliberately want it.
3. Paste the Bearer Token into the widget’s secure field and choose **Save token & enable paid X reads**. The token is stored in macOS Keychain and sent only to `api.x.com`; it never enters a model prompt.
4. Keep Codex signed in with ChatGPT. GPT-6 Luna reviews the retrieved public posts using your Codex plan. There is no separately billed OpenAI API call in this mode.

The reader examines original post text; it does not analyze images, videos or linked-page content. Green means no current announcement was found in the returned text, not a guarantee that no announcement exists in other formats. The reader resolves the four monitored accounts, caches their IDs for 24 hours and reads their public timelines—including replies and excluding reposts—over a fixed 48-hour window. It follows pagination and accepts a successful check only when all four accounts are covered. A complete set of empty timelines can establish no announcement in that window. Confirmed news cites an original returned post and an exact excerpt. Speculation, negation, routine resets and uncertain context remain yellow. An exact countdown requires an independently parsed original timestamp; other timing wording remains in the report.

A check reads at most 100 posts. The default daily cap is **200 post reads**, with selectable limits of 100, 200, 500, 1,000 or 2,000. Up to 12 account lookups are reserved separately per UTC day. Requests reserve their maximum possible returned resources before sending; unused reservations are returned only after a validated successful response. Timeouts and malformed responses may retain reservations conservatively. Analysis retries reuse the same successfully fetched snapshot. Busy feeds can exhaust the cap before the end of the day; raise it deliberately if you accept the cost. This release rechecks the full window rather than maintaining an incremental timeline archive.

At X’s published rates when this release was reviewed, a post read costs $0.005 and a user lookup $0.010: the default cap corresponds to up to $1 in post reads plus $0.12 in user lookups per UTC day, before any provider deduplication. X describes same-day resource deduplication as a soft guarantee. These are local resource caps, not a monetary guarantee; rates can change and other apps sharing your X project can also spend credits. **X’s console spending limit controls the project’s actual bill.** See the current [pricing and spending-limit documentation](https://docs.x.com/x-api/getting-started/pricing).

The app distinguishes rejected tokens, unavailable access/credits, provider rate limits, incomplete reads and local daily-budget pauses. It preserves the previous review and does not silently fall back to web search. Authenticated API access avoids the web-page access block, but still depends on X uptime, app permissions, credit balance and network access. No service can guarantee that every reset will be announced or every model interpretation will be correct.

### Other news checkers

**Codex · web search only** uses the existing ChatGPT sign-in in the installed Codex CLI and counts toward your plan usage. It needs no separate API key and never falls back to paid API requests. Web search may still fail to read original X pages. Settings identify the requested CLI model and, when returned by an API review, the actual response model.

The optional **OpenAI API · billed separately** checker uses exactly `gpt-6-luna` with hosted web search. Its key stays in macOS Keychain; model and search access depend on your API project. No other model is silently substituted.

All checkers share at most 48 attempts per UTC day, including retries, and a one-minute manual-check cooldown. Temporary failures receive up to two retries before the regular schedule resumes. The UI shows the last review, its age, the current failure and next retry. Plan checks pause when Codex quota is exhausted. X rate limits and local resource caps also pause direct checks. Increasing the X post cap clears only a local budget pause, not a provider rate limit or Codex quota hold.

Reset Radar supplies public news text, titles and URLs; personal harness quotas stay local. Codex checks run from a private temporary folder with project instructions and local execution tools disabled. Direct X reviews also disable web search. The CLI reuses your existing profile and may add installed skill names, paths and descriptions to its normal model context. It refuses nonempty global AGENTS instructions or integration settings that cannot safely be disabled; credentials are not copied into another profile. The optional OpenAI API mode disables response storage. Cached reviews become stale after two hours, and completed resets count as current news for 24 hours only.

The Mac must be awake and the app running. Codex quotas refresh every minute, the indirect feed every five minutes and connected usage files every five seconds. No cloud monitor is included.

## Local data and sharing

Preferences belong to `local.resetradar.widget`. News and optional connection files live under `~/Library/Application Support/ResetRadar`. The OpenAI key belongs to Keychain service `local.resetradar.openai`; the X Bearer Token belongs to `local.resetradar.x`. X account IDs and conservative read-budget counters stay local. Full X timelines are held in memory for a logical check; only the selected finding, excerpt and coverage metadata are saved. Rebuilding or replacing this locally signed app may cause macOS to request Keychain access again; approve it yourself in the secure prompt.

This folder is the intended GitHub source root. It contains no runtime data, account files, API keys, personal launch agent, binaries or machine-specific paths. Build products are ignored. Review [SECURITY.md](SECURITY.md) before distributing a release.

## License

Copyright (c) 2026 on9kitkit. Licensed under the [MIT License](LICENSE). The license is also included in the app package.
