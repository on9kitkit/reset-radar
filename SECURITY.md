# Security and privacy

## Boundaries

Reset Radar is a local macOS app, not an App Sandbox container. It runs as the signed-in user and intentionally launches a trusted local Codex CLI and user-approved status-line commands. It is not designed to defend against malicious software already running as that same macOS user. Choose executables, configuration files and exporters you trust.

The app has no listening server, telemetry collector, remote update mechanism or bundled credentials. Its two background HTTPS destinations are the fixed ModelYard feed and OpenAI Responses endpoint. Original X and provider documentation links open only when clicked. The feed is third-party, indirect evidence.

OpenAI API requests include an in-memory key read from macOS Keychain. Network requests use ephemeral sessions, no cookie jar or disk cache, ordinary platform TLS validation, no redirects, timeouts and a 2 MB decoded-response limit. Error messages do not echo remote bodies or credentials. `store: false` is sent to OpenAI; provider-side retention still follows the API account’s applicable policies.

The key is never included in this source package or quota files. Keychain reads, writes and removal run away from the UI thread; controls wait while the operation is pending. Removing a key disables monitoring and cancels the pending request before removing its local credential. It cannot undo an already-billed request.

## Input handling

Quota JSON reads are bounded to 256 KiB and accept only regular files. Exported provider IDs, percentages, dates, labels, counts and window IDs are validated. Missing or stale data does not become a fabricated 100% balance. Built-in readers save only explicitly selected quota fields. They forward the original payload to the pre-existing status-line command, as that command already received it; they do not persist prompts, project paths, email addresses, transcripts or tokens from the payload.

Local quota files, news cache and connection backups are written atomically using owner-only temporary files. Connection backups preserve the previous status-line command, which may itself contain sensitive user configuration; these backups remain local. Settings symlinks are resolved, unrelated settings are retained, managed-hook policy gates are respected and corrupt backups are kept for recovery. Configuration files should not be edited concurrently during connection/disconnection; JSON file updates cannot offer a transaction across third-party editors that do not cooperate with locks.

The original status-line command is trusted existing user configuration, not provider-supplied code. The bridge invokes that command through the shell with the same input; generated paths are shell-quoted. It stops the direct child process after three seconds. Descendants created by a user command can outlive that child; commands that start background jobs remain the user’s responsibility. The Codex child process is stopped after 25 seconds.

RSS parsing rejects DTDs and entity declarations, disables external entities and bounds entries and field lengths. Retrieved titles and posts are treated as untrusted evidence in the model prompt. The model has web search only, not local tools or credentials. X result URLs require the exact HTTPS host, author and numeric post route, with no credentials, custom port, query or fragment. Direct confirmation requires a completed original-page open in returned tool evidence; search sources or citations alone are insufficient. Inaccessible or ambiguous originals stay yellow. No model-assisted classifier can guarantee error-free news interpretation.

## Reporting and release

Do not paste keys, account data or full status-line payloads into public issues. If the future GitHub repository enables private vulnerability reporting, use its Security tab; otherwise contact the maintainer privately through a channel they provide. No reporting address has been invented for this unpublished project.

Before a public binary release, use a Developer ID certificate and notarization, test on a clean Mac, exercise the supported macOS versions and Intel hardware, and validate live Claude/Antigravity subscription connections. The current work is ready for source review, not a certification of zero bugs or a penetration test.
