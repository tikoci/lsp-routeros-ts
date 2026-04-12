# Source: https://forum.mikrotik.com/t/new-feature-back-to-home-vpn/168434/362
# Topic: NEW FEATURE: Back to Home VPN
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/cloud/back-to-home-users/add allow-lan=no comment="2nd user - added from RouterOS" name="$[/system identity get name] 2nd user" 
:delay 2s 
/ip/cloud/back-to-home-users/show-client-config [find name~"2nd"]
