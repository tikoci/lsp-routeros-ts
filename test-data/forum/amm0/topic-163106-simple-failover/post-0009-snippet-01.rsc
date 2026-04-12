# Source: https://forum.mikrotik.com/t/simple-failover/163106/9
# Topic: Simple failover?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

if ($bound = 1) do={
    /ip route
    remove [find where comment=WAN1]
    add dst-address=8.8.8.8 distance=1 scope=10 comment=WAN1 gateway=$"gateway-address"
}
