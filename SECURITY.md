# Security Policy

## Supported Versions

Only the latest published release is actively supported with security fixes.

| Version | Supported |
| ------- | --------- |
| latest  | ✅        |
| older   | ❌        |

## Reporting a Vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Report security issues privately via [GitHub's private vulnerability reporting](https://github.com/tikoci/lsp-routeros-ts/security/advisories/new).

Include:
- A description of the vulnerability and its potential impact
- Steps to reproduce or a proof-of-concept
- Any suggested mitigations

You can expect an initial response within a few days. If a fix is warranted, a patched release will be published and the advisory disclosed after the fix is available.

## Notes

This extension communicates with a **user-configured RouterOS device** over HTTP/HTTPS. The device address, credentials, and TLS behavior are controlled entirely by the user via extension settings. Treat your RouterOS credentials with the same care as any other network infrastructure credential.
