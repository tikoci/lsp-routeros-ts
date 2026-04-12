# Source: https://forum.mikrotik.com/t/simpler-failover-for-two-gateways-i-found-working/169108/26
# Topic: Simpler Failover for two Gateways I found working
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip firewall connection
:foreach idc in=[find where timeout>60] do={
 remove [find where .id=$idc]
}
