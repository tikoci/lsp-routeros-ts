# Source: https://forum.mikrotik.com/t/why-does-mikrotik-always-use-veth-in-a-bridge/168334/1
# Topic: Why does Mikrotik always use VETH in a bridge?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/bridge/add name=containers
/ip/address/add address=172.17.0.1/24 interface=containers
/interface/bridge/port add bridge=containers interface=veth1
