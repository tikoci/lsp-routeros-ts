# Source: https://forum.mikrotik.com/t/checking-recursive-route-values/167746/7
# Topic: Checking Recursive Route values
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local allRoutes [/ip route print as-value where active]
# one way is using :len... to know if you should put the first one...
:if ([:len $allRoutes] > 0) do={:put ($allRoutes->0)}
# or by it's type being NOT a nothing type...
:if ([:typeof ($allRoutes->0)] != "nothing") do={:put ($allRoutes->0))
}
