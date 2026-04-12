# Source: https://forum.mikrotik.com/t/v7-21rc-testing-is-released/266842/287
# Topic: V7.21rc [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    :local dstnats ([/app/get caddy firewall-redirects],"2019:2019:tcp:restapi")
    /app/set caddy firewall-redirects=$newdstnats
}
