# AGENTS.md — my-scripts

Personal library of sysadmin shell scripts (Ubuntu). No tests, CI, build system or dev
tooling. Scripts only, organized by platform.

## This repo is public

Everything here is world-readable forever, including headers, commit messages and history.

- No secrets, tokens, keys, passwords.
- No real IPs, hostnames, internal domains, personal paths (`/home/<name>`).
- No third-party personal data.
- Headers document the technique, not your machine.
- Never commit a secret to "fix it later" — history is permanent. Flag it instead.

## Layout

```
AGENTS.md          rules
README.md          script list + curl one-liners only
ubuntu/            per-platform scripts
```

No INDEX.md, no docs/, no extra markdown. Headers are the documentation.

## New script

1. Platform folder (`ubuntu/`, `arch/`, ...), kebab-case name.
2. ASCII header at the top, **Italian**, `┌─┐` borders 77 chars wide, sections:
   PERCHÉ QUESTO SCRIPT ESISTE / QUANDO ESEGUIRLO / USO / DETTAGLI TECNICI E AVVERTENZE.
3. One entry in README.md: `## name:platform`, one line, then the curl one-liner.
4. `chmod +x`.

## Code

- `set -euo pipefail`; if it must run via `curl | sh`, write POSIX sh (`set -eu`, pipefail if supported).
- `RED/GREEN/YELLOW/NC` + `log_ok`, `log_warn`, `log_err`.
- Root check at the start when needed.
- Idempotent: never wipe containers, images or user config on re-run.
- `apt-get -y` with `DEBIAN_FRONTEND=noninteractive`, `< /dev/null` on stdin-reading commands.
- No external deps beyond apt/systemd/dbus-tools.
- Messages in Italian.

## Rules

1. No dev boilerplate (editorconfig, linters, CI).
2. Commit messages: one line, Italian.
3. Script is the only source of truth.
4. README stays a bare list.
5. Many scripts run as root → always verify state before/after.
6. Public repo → rules above beat any convenience.
