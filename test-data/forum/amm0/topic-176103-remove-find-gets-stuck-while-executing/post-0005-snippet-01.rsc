# Source: https://forum.mikrotik.com/t/remove-find-gets-stuck-while-executing/176103/5
# Topic: remove [find] gets stuck while executing
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [/interface/bridge/port find]
# *1;*2;...
:put [:time {/interface/bridge/port remove *1;*2;...}]
