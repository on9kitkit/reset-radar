# Review record — version 4.6

Review date: 2 October 2026. This is a bounded engineering review, not a guarantee of zero defects.

## Report and verification display

Version 4.3 separates a reported reset from the ability to verify the original post. The UI preserves useful report text and the allowed source link, while exposing source access, freshness and check status separately. Indirect reports remain yellow; confirmed states and countdowns still require original-source evidence. Older caches remain readable without promoting ambiguous text into a new report classification.

Version 4.3 validation: both architectures compiled with warnings treated as errors. The complete offline suite passed, including reported-but-blocked news, safe consulted evidence links, stale/error preservation, rumor and contradictory-state handling, required API fields and backward cache compatibility. Archive manifest, metadata, signature and architecture checks passed. This does not establish live X accessibility.

## Connection and news update

Version 4.2 adds current ChatGPT-bundled Codex discovery, saved working-installation recovery, account-type and connection-error guidance, local-reader repair, GPT-6 Luna, and monitoring for @reach_vb plus the official OpenAI accounts. Yellow news now exposes its cause and a retry path. API checks allow six web-tool calls and 3,000 output tokens so a search can be followed by original-source checks. Indirect reset reports still cannot create confirmed states or countdowns.

Local validation on 26 September: the universal build and offline regression suite passed under Xcode 27 / Swift 6.4. Archive signature, metadata and both architectures passed package checks. The rebuilt app read the signed-in Codex account successfully without logging identity or balances, and the installed companion displayed current quota after restart. Live news model verification may require macOS Keychain approval after replacing an ad-hoc signed binary.

## Automated checks

- Apple Silicon and Intel compilation targeting macOS 13, with warnings treated as errors.
- Offline regression suite: click jitter and latched dragging; progressively smaller mascots and feet-to-head contact; saved stack order and visibility safeguards; remaining quota, countdowns and stale states.
- Claude and Antigravity documented input fixtures, missing/invalid quota, context-window separation, percentages, stale reports, unique windows and provider matching.
- Isolated end-to-end status-line installation, shell-quoted paths including spaces/apostrophes, original command output, repeated setup, disconnect restoration, newer edits, invalid settings and hook policy gates.
- Privacy filtering, owner-only file permissions, oversized-file rejection, nonblocking FIFO/directory rejection, symlink configurations and corrupt-backup preservation.
- Non-finite date and malformed Codex numeric handling, future cache rejection and conservative migration of older direct-news findings.
- Strict original X URLs, RSS dates, entity/DTD rejection, large XML fields, structured API output and original-page evidence requirements. Search-only evidence cannot confirm a reset.
- Offline network fixtures exercise real response handling: successful small responses, oversized streamed bodies and declared sizes. Redirect refusal and disabled session caching/cookies are checked.
- Clean source manifest and common secret-pattern scan; no account state or personal launch agent is included.

## Desktop and package checks

The release is checked on the development Apple Silicon Mac for scrollable settings, margins, accessible footer controls, hover-help metadata, resizing, companion expansion and preservation of the user’s stack. The live Codex account read is checked without printing balances or identity. The app archive is extracted and its local signature and both architectures verified before handoff.

## Remaining limits

- Live Claude Code and Antigravity subscription accounts are not connected on this Mac; their connectors are tested with isolated documented fixtures. Cursor, Grok and Muse require compatible usage files.
- The CI workflow compiles both architectures and runs offline tests on an Intel hosted runner. Interactive UI testing on Intel hardware remains outstanding. macOS 13 is the minimum compilation target; every supported OS version has not been tested.
- Developer ID signing, notarization and clean-Mac installation remain release work. MIT is confirmed; the copyright notice is Copyright (c) 2026 on9kitkit.
- X availability and model interpretation can fail. No checks guarantee advance notice of a surprise reset. Exact `gpt-6-luna` API access remains dependent on the user’s OpenAI project; the app does not substitute another model.
- The source scan detects common credential patterns and excludes unexpected package files. It is not a comprehensive secret-discovery product or external penetration test.
- Existing user status-line commands are trusted. Background descendants and concurrent edits by other programs are outside the connector’s transaction guarantees.

This record describes the local pre-publication review. The repository contains only the reviewed source package; the surrounding working directory, local app data and generated build products are excluded. Hosted CI is defined in `.github/workflows/ci.yml`; its run history records execution results for each commit. Public binary release work remains separate.

## Hosted automation

The `Build and test` workflow checks source privacy (including tracked files), shell/plist syntax, universal compilation with active assertions, offline regressions and the final app archive. Archive checks include approved contents, matching license/guide, metadata, filename-only SHA-256, extracted signature and both architectures. It uses macOS 15 Intel with Xcode 16.4; no live credentials, paid API requests or release signing are needed. See the workflow run for a commit’s actual result rather than treating this document as a permanent passing status.

## Supplied discovery evidence

Version 4.3.1 addresses a live finding where an explicit report from the supplied discovery feed was discarded because it was not repeated in web-tool source metadata. The review now carries the same bounded, fresh candidate snapshot through the request and response validation. Matching supplied candidates count only as indirect report evidence; they cannot establish original verification or an announced countdown.

Validation: universal compilation with warnings treated as errors, the complete offline regression suite, source privacy checks and package validation passed for 4.3.1. The installed app restarted successfully. A fresh paid news check remains dependent on macOS granting the replacement binary access to the saved Keychain item.

## Plan-based news checker

Version 4.4 adds a Codex CLI news checker using the existing ChatGPT sign-in, preserving the optional separately billed OpenAI API checker. The timeout investigation found that web-search reviews could exceed the previous 90–100 second request window, after which the next attempt waited the full hourly interval. The new scheduler bounds transient retries, keeps the last successful review and makes the next retry visible. Paid API fallback is never automatic.

The installed CLI was tested with GPT-6 Luna, live web search and a blocked original X post. Its recorded web results allow source validation; a guessed source URL or an error page is not evidence of a directly verified reset. Final release validation is recorded below after the integrated build.

Version 4.4 final validation on 2 October 2026: both architectures compiled with warnings treated as errors; the complete offline suite, archive signature/metadata/architecture checks, source privacy scan and whitespace checks passed. Twelve additional independent adversarial fixtures passed. The installed widget completed a live GPT-6 Luna Codex-plan check using its existing sign-in, without API Keychain access. That check returned uncertainty because X blocked original posts and accessible search results did not establish current evidence; no confirmed state or reset time was fabricated. Hourly plan monitoring was enabled. Hosted CI is recorded in the pushed commit’s workflow history.

## Authenticated X connection

Version 4.5 adds direct app-only X timeline reads and a secure Keychain token field, with explicit paid-read activation, console links and daily resource caps. The Codex plan analyzes supplied original texts with web search disabled. Complete coverage is generated by the client rather than the model; incomplete pages cannot establish green. Red requires a matching source and quoted commitment, with conservative wording guards. A countdown needs a matching independently parsed original timestamp.

Offline fixtures cover full and empty coverage, pagination, missing/partial account data, author binding, long-form text, malformed and truncated responses, field-name compatibility, rate limits, daily reservations and UTC rollover, cancellation, retry snapshot reuse, source/quote matching, ambiguous wording, invented timing and cache provenance. No live X token is available during this review; actual app entitlement, credits and end-to-end X access must be verified after the user saves their token. No X API call or purchase is made by the build or test suite.

Version 4.5 local validation: Apple Silicon and Intel builds with warnings treated as errors, the complete offline suite, source privacy scan, whitespace checks and package signature/manifest checks passed. A separate reviewer’s harness and seven additional adversarial wording/timing fixtures passed. The live X connection remains unverified until the user supplies their own token. Hosted CI results belong to the matching commit’s run history.

## Recent web-search coverage

Version 4.6 separates completed recent account searches from original-page access. The web checker requests four exact account-specific queries over a bounded UTC date window; coverage comes from actual completed search-call metadata. A completed empty or historical result set can support a green **No reset found in search** result without requiring an unrelated recent post. Missing, failed or error-page-only searches cannot. A historical original returning 403 no longer invalidates independent successful searches. Current explicit claims and ambiguous news still require their existing reported/verified handling; search alone cannot turn a reset red or establish an announced countdown.

The version 6 cache requires consistent no-announcement classification, a complete client-generated receipt set, matching backend and request time, and no contradictory current explicit-claim observation. Legacy web no-announcement caches require a fresh review. Green is limited to returned search results; it does not guarantee complete indexing of X posts.

Version 4.6 final validation on 2 October 2026: both architectures compiled with warnings treated as errors; the complete offline suite, source privacy scan, whitespace checks and archive signature/manifest checks passed. An independent review passed 23 additional cases and reviewed five final malformed-status/query regression fixtures. The installed widget completed a live Codex-plan check with GPT-6 Luna requested, recorded the exact recent queries for all four accounts and displayed green **No reset found in search** with **Search checked** in both settings and the compact companion. The CLI did not supply separate actual-model metadata; the UI identifies the requested model accordingly. No OpenAI API or X API call was made for this live check. Hourly plan monitoring remains enabled. Hosted CI belongs to the matching pushed commit’s workflow history.
