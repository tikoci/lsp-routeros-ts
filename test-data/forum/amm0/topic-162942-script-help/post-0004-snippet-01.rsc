# Source: https://forum.mikrotik.com/t/script-help/162942/4
# Topic: script-help
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:if ([/ping 192.168.88.1 as-value count=1]->"status" != "timeout") do={
   /log info [/interface ethernet cable-test ether2 duration=3 as-value]
}
