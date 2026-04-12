# Source: https://forum.mikrotik.com/t/mikrotik-atl-lte18-in-bridged-mode/176329/6
# Topic: Mikrotik ATL LTE18 in Bridged Mode
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/address/add interface=bridge address=<your-management-ip>   
/ip/dhcp-server/set [find] disable
/ip/route/add dst=0.0.0.0/0 gateway=<your-management-subnet-default-gateway>
