# Source: https://forum.mikrotik.com/t/v7-17beta-testing-is-released/179003/287
# Topic: v7.17beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system/device-mode/print
#       mode: advanced
#       container: yes     
/system/device-mode/print <tab>
# as-value     file     interval     without-paging  
:put [/system/device-mode/get]         
# container=true;mode=advanced
