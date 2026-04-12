# Source: https://forum.mikrotik.com/t/what-does-op-type-do/182894/3
# Topic: What does op type (>[ ... ]) do?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:local newarray [:toarray ""]
:set ($newarray->"var1") "data"  
:set ($newarray->"var2") 2  
:set ($newarray->"fn1") do={:return "something"}
