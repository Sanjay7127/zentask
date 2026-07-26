# Security Policy

ZenTask is a local-first productivity app: by default, all data lives only on
the user's device. This policy covers both the app itself and the small
amount of infrastructure (optional cloud sync, optional AI planner) that only
activates when a user explicitly supplies their own credentials.

## Supported versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |
| < 0.1   | :x:                |

ZenTask is pre-1.0 — security fixes land on the latest `0.1.x` release.
Once a `1.0.0` is tagged, this table will be updated with a formal support
window.

## Reporting a vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Instead, report it privately via **GitHub Private Vulnerability
Reporting**: open the [Security tab](https://github.com/Sanjay7127/zentask/security/advisories/new)
on this repository and submit a draft security advisory.

Please include:

- A clear description of the vulnerability and its impact.
- Steps to reproduce (a minimal repro project or code snippet helps a lot).
- The ZenTask version / commit hash you tested against.
- Your assessment of severity, if you have one.

## What to expect

| Stage                     | Target time      |
| ------------------------- | ---------------- |
| Acknowledgement of report | Within 3 days    |
| Initial triage/assessment | Within 7 days    |
| Fix or mitigation plan    | Depends on severity, communicated after triage |

We'll keep you updated as the issue is investigated, and credit you in the
release notes / advisory (unless you'd prefer to stay anonymous).

## Disclosure policy

- We follow **coordinated disclosure**: please give us a reasonable window
  to investigate and ship a fix before any public disclosure.
- Once a fix is released, we'll publish a GitHub Security Advisory
  describing the issue, affected versions, and the fix — crediting the
  reporter unless anonymity is requested.
- If a report turns out to be a non-issue or out of scope, we'll explain why
  and close it transparently.

## Scope notes specific to this app

- **Local storage**: ZenTask uses [Hive](https://pub.dev/packages/hive) for
  on-device storage, with an *opt-in* AES-256 encryption mode (Settings →
  Security & Privacy). Encryption is off by default for new installs until a
  user turns it on.
- **Biometric app lock**: implemented via
  [`local_auth`](https://pub.dev/packages/local_auth), deferring to the
  OS's own biometric/passcode APIs — ZenTask never handles raw biometric
  data itself.
- **Cloud sync / AI planner**: both are optional and inactive unless the
  user supplies their own Supabase/Anthropic credentials
  (`config/cloud_config.json`, gitignored — see `DEVELOPER_GUIDE.md`). No
  credentials ship with this repository.
- **Telemetry**: crash reporting and product analytics
  (`lib/services/crash/`, `lib/services/telemetry/`) are local-only by
  default — no data leaves the device unless a real backend is wired in by
  a maintainer.

If you're unsure whether something is a security issue or just a bug,
err on the side of reporting it privately — we'd rather triage a
false positive than miss a real report.
