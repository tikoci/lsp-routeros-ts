# Source: https://forum.mikrotik.com/t/how-to-access-time-with-milliseconds-in-a-script/179598/3
# Topic: How to access time with milliseconds in a script?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{ 
:local ts1 [:timestamp]
:delay 1ns
:local ts2 [:timestamp] 
:put ($ts1-$ts2) 
:put [:tonsec ($ts1-$ts2)]
}
# -00:00:00.000084760
# -84760
# Warning: value of delay-time was rounded down to 0s
