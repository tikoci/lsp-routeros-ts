# Source: https://forum.mikrotik.com/t/get-two-public-ip-on-the-same-interface/175540/9
# Topic: Get Two public IP on the same interface
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/firewall/nat
add action=src-nat chain=srcnat out-interface=ether1 per-connection-classifier=both-addresses-and-ports:2/0 to-address=156.55.55.2
add action=src-nat chain=srcnat out-interface=ether1 per-connection-classifier=both-addresses-and-ports:2/1 to-address=156.55.55.3
