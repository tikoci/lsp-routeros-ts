# Source: https://forum.mikrotik.com/t/script-not-running/176370/3
# Topic: Script not running
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{ 
:local semi {{"mateo";"mateo@example.com"};{"sofia";"sofia@example.com"}}
:put $semi
# mateo;mateo@example.com;sofia;sofia@example.com
:local comma ({"mateo";"mateo@example.com"},{"sofia";"sofia@example.com"})
:put $comma
# mateo;mateo@example.com;sofia;sofia@example.com

# they look the same, but not same when accessing...
:put ($semi->1->1)
# sofia@example.com
:put ($comma->1->1)
# (gets nothing)

# and only the comma version has a 3rd element...
:put ($semi->3)
# (gets nothing)
:put ($comma->3)
# sofia@example.com

# BOTH out put of :put look IDENTICAL
}
