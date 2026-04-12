# Source: https://forum.mikrotik.com/t/yaml-convert-arrays-to-pretty-yaml-formated-text/169590/1
# Topic: $YAML - convert arrays to pretty YAML-formated text
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global myarray {
    "system"=[/system resource print as-value];
    "ipaddr"=[/ip address print as-value];
    "iproutes"=[/ip route print as-value];
    "ipconns"=[/ip firewall connection print as-value]}
