# Source: https://forum.mikrotik.com/t/copy-firewall-rules-and-settings/266277/3
# Topic: Copy Firewall Rules and settings
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global allowAddress do={
   /ip/firewall/filter add action=accept chain=input dst-address=$1 place-before=1
}
