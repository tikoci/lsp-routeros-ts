# Source: https://forum.mikrotik.com/t/checking-recursive-route-values/167746/7
# Topic: Checking Recursive Route values
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    :foreach foundItem in=[/ip/route/print as-value] do={
        # print all attributes for current route in loop
        :put $foundItem
        # print just the comment attribute - note the quotes since each route is a map of the attributes
        :put ($foundItem->"comment")

        # since the $foundItem is an array map...
        # we can loop  and get BOTH attribute and values for the current route
        :foreach routeAttr,attrValue in=$foundItem do={
            :put "$routeAttr is set to $attrValue"
        }
    }
}
