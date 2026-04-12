# Source: https://forum.mikrotik.com/t/auto-discover-device-update/156396/15
# Topic: Auto Discover Device + Update
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global namedmikrotik [/ip neighbor find identity="MikroTik"]
:put $namedmikrotik
:global firstip  [/ip neighbor get [:pick $namedmikrotik 1] address4]
:put $firstip
# then you can run /tool/fetch + :import OR you can use SSH to issue commands:
/system ssh command="/ip address print" user=admin address=$firstip
