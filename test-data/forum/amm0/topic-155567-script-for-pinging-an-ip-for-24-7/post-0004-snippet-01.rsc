# Source: https://forum.mikrotik.com/t/script-for-pinging-an-ip-for-24-7/155567/4
# Topic: Script for pinging an IP for 24/7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global lastping [/ping address=8.8.8.8 count=1 as-value]
:put $x
  # .id=*0;host=8.8.8.8;seq=0;size=56;time=00:00:00.002854;ttl=117
:put ($x->"ttl")
  # 117
