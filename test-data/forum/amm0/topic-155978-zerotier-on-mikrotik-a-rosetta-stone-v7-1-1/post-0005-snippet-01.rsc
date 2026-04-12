# Source: https://forum.mikrotik.com/t/zerotier-on-mikrotik-a-rosetta-stone-v7-1-1/155978/5
# Topic: ZeroTier on Mikrotik – a rosetta stone [v7.1.1+]
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/firewall/connection/print where dst-address~"9993"
/zerotier/peer/print
/ip/firewall/connection/print where dst-address~"9993" timeout<30s
