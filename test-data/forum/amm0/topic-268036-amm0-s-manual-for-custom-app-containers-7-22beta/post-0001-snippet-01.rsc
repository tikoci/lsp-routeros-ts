# Source: https://forum.mikrotik.com/t/amm0s-manual-for-custom-app-containers-7-22beta/268036/1
# Topic: 📚 Amm0's Manual for "Custom" /app containers (7.22beta+)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/app add disabled=no yaml="
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
      - 2323:23/tcp:telnet
    restart: unless-stopped
"
