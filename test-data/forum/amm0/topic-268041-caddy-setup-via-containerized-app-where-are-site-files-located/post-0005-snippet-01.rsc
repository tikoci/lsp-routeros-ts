# Source: https://forum.mikrotik.com/t/caddy-setup-via-containerized-app-where-are-site-files-located/268041/5
# Topic: Caddy setup via Containerized App: where are site files located
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/file add name="$[/app/settings/get disk]/apps/caddy/caddy-site/index.html" contents="<html><body>Hello</body></html>"
