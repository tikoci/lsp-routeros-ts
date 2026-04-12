# Source: https://forum.mikrotik.com/t/container-traefik-on-rb5009/165849/7
# Topic: Container "Traefik" (on RB5009)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global rootdisk "raid1-part1"
/interface/veth/add name=veth-traefik address=172.18.18.18/24 gateway=172.18.18.1
/ip/address/add interface=veth-traefik address=172.18.18.1/24
/container add interface=veth-traefik logging=yes mounts=TRAEFIK_ETC root-dir="$rootdisk/traefik-etc"
/container add root-dir="$rootdisk/traefik-root" remote-image=library/traefik:v2.10 logging=yes interface=veth-traefik mounts=TRAEFIK_ETC
/container start
