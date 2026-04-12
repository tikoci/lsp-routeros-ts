# Source: https://forum.mikrotik.com/t/amm0s-forum-plugins-tests-routeros-graphviz-diagrams-colors/261912/3
# Topic: Amm0's Forum Plugins Tests — ` ` `routeros & [graphviz] diagrams & colors
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
     :put "
[graphviz engine=patchwork]
graph {
    layout=patchwork
    node [style=filled]
"
    :foreach a in=[/ip/firewall/filter/print stats as-value] do={
       :put "\"$[:pick ($a->".id") 1 10]\"  [ area=$($a->"packets") label=\"$($a->"chain") $($a->"action")\" tooltip=\"$($a->"comment")\" fontsize=128 fillcolor=$[(>[:if ($a->"dynamic") do={:return "silver"} else={:return "gold"}])] ]"
    }     
    :put "
}
[/graphviz]" 
}
