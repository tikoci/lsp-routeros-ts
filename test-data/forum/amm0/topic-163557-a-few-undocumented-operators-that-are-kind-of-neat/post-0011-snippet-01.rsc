# Source: https://forum.mikrotik.com/t/a-few-undocumented-operators-that-are-kind-of-neat/163557/11
# Topic: A few undocumented operators that are kind of neat.
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global add do={ ($1 + 1) } 
:put ($add <%% $add <%% $add <%% $add <%% $add <%% {0})
;5
