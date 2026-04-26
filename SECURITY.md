# Security Policy

## Reporting a Vulnerability

Report privately via [GitHub Security Advisories](https://github.com/tikoci/lsp-routeros-ts/security/advisories/new). Do **not** open a public issue for an undisclosed vulnerability.

Please include a description of the vulnerability and its impact, steps to reproduce or a proof-of-concept, and any suggested mitigations. Initial response within a few business days; if a fix is warranted, a patched release is published and the advisory disclosed after the fix is available.

## Scope

This is a Language Server Protocol implementation for MikroTik RouterOS scripting. At runtime it:

- Talks to a **user-configured RouterOS device** over HTTP/HTTPS — address, credentials, and TLS behavior are controlled entirely by the user via extension settings or `ROUTEROSLSP_*` env vars. Treat your RouterOS credentials with the same care as any other network infrastructure credential.
- Ships across six deployment contexts (VSCode Desktop, VSCode Web, standalone binary, npm `@tikoci/routeroslsp`, NeoVim, Copilot CLI). Each is documented in `.github/instructions/deployment.instructions.md`.
- Bypasses self-signed-certificate checks by default on the Node target (`rejectUnauthorized: false`). The Web target cannot bypass certificate checks and requires a CORS proxy.

## Code scanning

The repository's [Security tab](https://github.com/tikoci/lsp-routeros-ts/security) is the live source of current alerts and advisories. This section describes *what* runs and *why*.

- **CodeQL** — GitHub [Default Setup](https://github.com/tikoci/lsp-routeros-ts/settings/security_analysis). Query suite: `default`. Languages: `javascript-typescript`, `actions`. Schedule: weekly + on push/PR. There is no `codeql.yml` workflow in the repo by design — configuration is held by GitHub and readable via `gh api repos/tikoci/lsp-routeros-ts/code-scanning/default-setup`.
- **Code Quality (AI findings, preview)** — enabled. AI findings are noisy and self-contradicting; we accept the noise because the second-opinion catches real issues that the static suite misses. Steady-state goal is 0 open findings. False positives are dismissed via the GitHub UI with a written justification — that text is the audit-log contract. CI carries a forward-compatible probe step ("AI findings probe" in [`.github/workflows/ci.yaml`](.github/workflows/ci.yaml)) that polls candidate REST endpoints and prints a notice today; once GitHub ships a stable API the same step starts surfacing counts as warnings without ever blocking a PR.
- **Dependency review** — [`.github/workflows/dependency-review.yml`](.github/workflows/dependency-review.yml), `fail-on-severity: high` on pull requests.
- **Dependabot security updates** — not enabled.
- **Secret scanning** — enabled.
- **Private vulnerability reporting** — enabled.

This is the most widely used tikoci project (thousands of VSCode Marketplace installs); we treat the steady-state `0 open findings` posture as load-bearing — see "Security badge" in `CLAUDE.md` for the policy that drives this.

## Supported versions

| Version | Supported |
| --- | --- |
| latest published release | ✅ |
| older | ❌ |
