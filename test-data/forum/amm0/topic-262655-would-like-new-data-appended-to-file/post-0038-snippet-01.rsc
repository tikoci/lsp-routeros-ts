# Source: https://forum.mikrotik.com/t/would-like-new-data-appended-to-file/262655/38
# Topic: Would like new data appended to file
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system/ups {
   :foreach ups in=[find] do={
       :log info [:put [monitor $ups once as-value]]
    }
}
