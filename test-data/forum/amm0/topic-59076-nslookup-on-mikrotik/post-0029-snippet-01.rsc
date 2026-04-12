# Source: https://forum.mikrotik.com/t/nslookup-on-mikrotik/59076/29
# Topic: nslookup on Mikrotik
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[admin@Mikrotik] /ip/address> put [resolve dishy.starlink.com server=8.8.8.8]
bad command name resolve (line 1 column 6)
[admin@Mikrotik] /ip/address> :put [:resolve dishy.starlink.com server=8.8.8.8]
192.168.100.1
