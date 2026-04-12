# Source: https://forum.mikrotik.com/t/v7-22beta-development-is-released/267611/268
# Topic: V7.22beta [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/app add network=internal use-https=no disabled=no auto-update=yes yaml="
name: cligames
descr: Amm0's BSD games for RouterOS
page: https://github.com/tikoci/cligames
category: games
icon: https://wiki.pine64.org/images/b/bc/BSD_Unix_icon.png
default-credentials: joshua:(none)
services:
  cligames:
    image: ghcr.io/tikoci/cligames:latest
    environment:
      TERM: screen
    ports:
      - 2323:23:telnet:tcp
    restart: unless-stopped
"
