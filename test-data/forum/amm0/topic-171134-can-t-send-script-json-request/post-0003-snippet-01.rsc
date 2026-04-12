# Source: https://forum.mikrotik.com/t/cant-send-script-json-request/171134/3
# Topic: Can't send script json request
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/wireguard/peers/enable [find public-key="public-key"]
:delay 5s
/interface/wireguard/peers/disable [find public-key="public-key"]
