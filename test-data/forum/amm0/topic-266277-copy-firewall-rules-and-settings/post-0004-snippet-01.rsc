# Source: https://forum.mikrotik.com/t/copy-firewall-rules-and-settings/266277/4
# Topic: Copy Firewall Rules and settings
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# 2025-11-09 02:31:45 by RouterOS 7.20.2
# software id = RGLC-XXXX
#
# model = C52iG-5HaxD2HaxD
# serial number = XXXXX

# customizable variables:
:global ipaddress 10.88.2.1/24

# modified `export` with variables:
... more config
/ip address
add address=$ipaddress comment=defconf interface=bridge 
... more config
