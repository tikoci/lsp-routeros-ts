# Source: https://forum.mikrotik.com/t/containers-wont-start-on-rb3011-uias/178803/6
# Topic: Containers wont start on RB3011 UiAS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface veth add address=172.19.6.2/24 gateway=172.19.6.1 name=veth-alpine
/ip address add address=172.19.6.1/24 interface=veth-alpine network=172.19.6.0
/ip firewall nat add action=masquerade chain=srcnat out-interface=veth-alpine place-before=1 
:global alpine [/container add cmd="ping 8.8.8.8" interface=veth-alpine remote-image=alpine:latest logging=yes]
:delay 5s
/container start $alpine
:delay 5s
/log/print where message~"8.8.8.8"
