# Source: https://forum.mikrotik.com/t/fast-and-accurate-leap-year-calculation/152405/8
# Topic: Fast and Accurate Leap Year calculation
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [:time command={:put [$strmonths]}] 
jan;feb;mar;apr;may;jun;jul;aug;sep;oct;nov;dec
00:00:00.000414

:put [:time command={:put [$arrmonths]}] 
jan;feb;mar;apr;may;jun;jul;aug;sep;oct;nov;dec
00:00:00.000215
