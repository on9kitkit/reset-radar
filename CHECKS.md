# Review record — version 4.1

Review date: 12 September 2026. This is a bounded engineering review, not a guarantee of zero defects.

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
- X availability and model interpretation can fail. No checks guarantee advance notice of a surprise reset. Exact `gpt-5.6-luna` API access remains dependent on the user’s OpenAI project; the app does not substitute another model.
- The source scan detects common credential patterns and excludes unexpected package files. It is not a comprehensive secret-discovery product or external penetration test.
- Existing user status-line commands are trusted. Background descendants and concurrent edits by other programs are outside the connector’s transaction guarantees.

This record describes the local pre-publication review. The repository contains only the reviewed source package; the surrounding working directory, local app data and generated build products are excluded. Hosted CI is defined in `.github/workflows/ci.yml`; its run history records execution results for each commit. Public binary release work remains separate.

## Hosted automation

The `Build and test` workflow checks source privacy (including tracked files), shell/plist syntax, universal compilation with active assertions, offline regressions and the final app archive. Archive checks include approved contents, matching license/guide, metadata, filename-only SHA-256, extracted signature and both architectures. It uses macOS 15 Intel with Xcode 16.4; no live credentials, paid API requests or release signing are needed. See the workflow run for a commit’s actual result rather than treating this document as a permanent passing status.
