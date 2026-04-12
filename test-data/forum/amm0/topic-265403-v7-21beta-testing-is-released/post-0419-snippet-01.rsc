# Source: https://forum.mikrotik.com/t/v7-21beta-testing-is-released/265403/419
# Topic: V7.21beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global somelansubnet 192.168.100.1/24
:put "typeof $[:typeof $somelansubnet] does work with toip: $[:toip $somelansubnet]"
# typeof ip-prefix does work with toip: 192.168.100.1
