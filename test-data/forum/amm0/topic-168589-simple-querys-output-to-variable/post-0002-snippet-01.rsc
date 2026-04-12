# Source: https://forum.mikrotik.com/t/simple-querys-output-to-variable/168589/2
# Topic: Simple querys output to variable
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global portprint [/port print detail as-value]
:global userprint [/user print detail as-value]
:put " Ports:\n $portprint \n\n Users:\n $userprint "
