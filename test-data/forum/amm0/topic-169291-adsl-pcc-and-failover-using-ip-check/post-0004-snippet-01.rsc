# Source: https://forum.mikrotik.com/t/adsl-pcc-and-failover-using-ip-check/169291/4
# Topic: ADSL pcc and failover using IP check
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:if ($bound=1) do={ 
   /ip route set [ /routing/route/find dst-address="0.0.0.0/0" gateway=$"gateway-address" ] check-gateway=ping 
}
