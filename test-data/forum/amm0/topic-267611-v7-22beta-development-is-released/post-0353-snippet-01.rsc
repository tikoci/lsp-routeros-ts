# Source: https://forum.mikrotik.com/t/v7-22beta-development-is-released/267611/353
# Topic: V7.22beta [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

-
  name: bind9
  services:
    bind9:
      ports:
          - 53:53/udp:dns
          - 53:53/tcp:dns
      image: docker.io/internetsystemsconsortium/bind9:9.18
-
  name: unbound
  services:
    unbound:
      ports:
          - 53:53/tcp:dns
          - 53:53/udp:dns
      image: docker.io/klutchell/unbound:latest
