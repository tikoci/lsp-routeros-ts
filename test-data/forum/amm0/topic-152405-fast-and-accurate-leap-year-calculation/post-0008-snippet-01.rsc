# Source: https://forum.mikrotik.com/t/fast-and-accurate-leap-year-calculation/152405/8
# Topic: Fast and Accurate Leap Year calculation
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global strmonths do={:return [:toarray "jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec"]}      
# vs
:global arrmonths do={:return ("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec")}
