# Source: https://forum.mikrotik.com/t/checking-recursive-route-values/167746/9
# Topic: Checking Recursive Route values
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global rtall ([/ip route print detail as-value where active and routing-table=main and comment~".*"])
# show the length (e.g. number of routes that match the "where")
:put [:len $rtall]
# first match...
:put ($rtall->0->"gateway")
:put ($rtall->0->"dst-address")
# 2nd match
:put ($rtall->1->"gateway")
:put ($rtall->1->"dst-address")
