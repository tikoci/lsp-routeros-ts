# RouterOS LSP setup walkthrough

RouterOS LSP needs a live RouterOS REST connection. The extension asks RouterOS
for syntax information through `/rest/console/inspect`, so features such as
semantic highlighting, diagnostics, and completion do not work until connection
settings are configured.

## 1. Enable REST access on RouterOS

RouterOS REST uses the `www` or `www-ssl` service. For a basic LAN setup:

```routeros
/ip/service enable www
```

HTTPS is preferred when you have a trusted certificate:

```routeros
/certificate/enable-ssl-certificate
/ip/service enable www-ssl
```

## 2. Create a limited LSP user

Normal LSP editing features only need read access to the REST API:

```routeros
/user/group add name=lsp policy=read,api,rest-api
/user add name=lsp password=<strong-password> group=lsp
```

Do not use this read-only account for script execution. Write operations require
explicit per-call credentials and should use a separate RouterOS user with the
minimum write policy needed for that operation.

## 3. Configure VSCode settings

Open **Settings** and search for **RouterOS LSP**, or run
**RouterOS LSP: Show Settings** from the Command Palette.

Set:

| Setting | Example | Notes |
| --- | --- | --- |
| `routeroslsp.baseUrl` | `http://192.168.88.1` | Protocol and host; no trailing slash. |
| `routeroslsp.username` | `lsp` | RouterOS user with `read,api,rest-api`. |
| `routeroslsp.password` | `<strong-password>` | Stored in VSCode settings. |
| `routeroslsp.apiTimeout` | `15` | Increase for slow routers or large scripts. |

Open a `.rsc` file after saving settings. The extension activates automatically
for RouterOS scripts.

## 4. Test the connection

Run **RouterOS LSP: Test RouterOS Connection** from the Command Palette. If it
fails, open **RouterOS LSP: Show Logs** and check:

- the URL includes the correct protocol and port;
- the RouterOS REST service is enabled;
- the username/password are correct;
- firewalls allow the editor machine to reach RouterOS;
- HTTPS certificates are trusted by the environment.

## 5. VSCode Web note

`vscode.dev` and `github.dev` run in a browser and need a CORS-capable HTTPS
proxy in front of RouterOS. See [`docs/cors.md`](cors.md) for proxy examples.
