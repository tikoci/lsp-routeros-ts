# Source: https://forum.mikrotik.com/t/caddy-setup-via-containerized-app-where-are-site-files-located/268041/5
# Topic: Caddy setup via Containerized App: where are site files located
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/container stop app-caddy
:delay 5s
/container start app-caddy
