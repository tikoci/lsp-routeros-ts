# Source: https://forum.mikrotik.com/t/time-parsing-in-7-1/154185/3
# Topic: time parsing in 7.1
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system/ssh address=192.168.x.y user=usr command="date +%s"
# 1640195280
:put [$unixT2S]
# 1640192640
/system/ssh address=192.168.x.y user=usr command="date -r $([$unixT2S])"
# Wed Dec 22 09:02:46 PST 2021
:put [/system/clock/get date]
# dec/22/2021
:put [/system/clock/get time]
# 09:24:52
