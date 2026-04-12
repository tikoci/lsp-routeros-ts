# Source: https://forum.mikrotik.com/t/how-to-access-time-with-milliseconds-in-a-script/179598/3
# Topic: How to access time with milliseconds in a script?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [:timestamp]
# 2859w6d10:50:42.236575187
:put [:tonsec [:timestamp]]
# 1729680660992477203
