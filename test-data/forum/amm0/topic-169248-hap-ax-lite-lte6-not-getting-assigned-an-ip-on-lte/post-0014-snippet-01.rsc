# Source: https://forum.mikrotik.com/t/hap-ax-lite-lte6-not-getting-assigned-an-ip-on-lte/169248/14
# Topic: hAP ax lite LTE6 - Not getting assigned an IP on LTE
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:if ($bound=1) do={ 
   /ip route set [ /routing/route/find dst-address="0.0.0.0/0" gateway=$"gateway-address" ] check-gateway=ping 
}
