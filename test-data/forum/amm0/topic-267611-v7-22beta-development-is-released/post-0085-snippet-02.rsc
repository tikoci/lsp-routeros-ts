# Source: https://forum.mikrotik.com/t/v7-22beta-development-is-released/267611/85
# Topic: V7.22beta [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system/note set note=""
:delay 1s
/log info "log something"
:delay 1s
:put [/system/note get note]
