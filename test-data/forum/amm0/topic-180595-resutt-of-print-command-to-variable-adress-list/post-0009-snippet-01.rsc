# Source: https://forum.mikrotik.com/t/resutt-of-print-command-to-variable-adress-list/180595/9
# Topic: Resutt of print command to variable adress list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:foreach ipaddr in=[/ip/kid-control/device/find activity~"YouTube"] do={
     /ip/firewall/address-list name=ytkids timeout=1h address=[/ip/kid-control/device/get $ipaddr ip-address]
}
