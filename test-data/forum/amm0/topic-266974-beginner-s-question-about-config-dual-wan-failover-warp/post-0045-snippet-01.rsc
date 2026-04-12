# Source: https://forum.mikrotik.com/t/beginners-question-about-config-dual-wan-failover-warp/266974/45
# Topic: Beginner's question about config dual wan failover + warp
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:serialize to=dsv delimiter=, [/ip/route print detail as-value] options=dsv.remap file-name=ipv4routes.csv                      
:serialize to=dsv delimiter=, [/routing/route print detail as-value] options=dsv.remap file-name=allroutes.csv
:serialize to=dsv delimiter=, [/routing/nexthop print detail as-value] options=dsv.remap file-name=nexthops.csv
