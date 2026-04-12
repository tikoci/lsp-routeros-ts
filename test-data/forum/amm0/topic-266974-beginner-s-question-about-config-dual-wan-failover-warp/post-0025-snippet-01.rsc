# Source: https://forum.mikrotik.com/t/beginners-question-about-config-dual-wan-failover-warp/266974/25
# Topic: Beginner's question about config dual wan failover + warp
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/route
add dst-address=208.67.222.222 gateway=10.111.0.1 scope=10
add dst-address=208.67.220.220 gateway=10.112.0.1 scope=10
add distance=1 gateway=208.67.222.222 target-scope=11 check-gateway=ping
add distance=2 gateway=208.67.220.220 target-scope=11 check-gateway=ping
