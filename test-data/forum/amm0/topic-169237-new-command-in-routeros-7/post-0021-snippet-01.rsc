# Source: https://forum.mikrotik.com/t/new-command-in-routeros-7/169237/21
# Topic: New command in RouterOs 7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:retry delay=1s max=3 on-error={:put "got an error"} command={:put [/system/identity/get name]}
# Mikrotik
:retry delay=1s max=3 on-error={:put "I give up!"} command={:put "trying..."; :error "cause error"}                                
# trying...
# trying...
# trying...
# I give up!
