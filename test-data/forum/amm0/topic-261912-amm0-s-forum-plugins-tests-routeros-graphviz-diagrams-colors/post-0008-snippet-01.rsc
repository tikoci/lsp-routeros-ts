# Source: https://forum.mikrotik.com/t/amm0s-forum-plugins-tests-routeros-graphviz-diagrams-colors/261912/8
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
  :local fontsize (3*1024)
  :local color "CornflowerBlue"
  :if (($a->"action")~"(drop|tcp-reset)") do={:set color "Firebrick"}
  :if (($a->"action")~"(accept)") do={:set color "LawnGreen"}
  :local extra ""
  :if (($a->"chain")~"(forward)") do={:set extra "gradientangle=90"}
  :put "\"$[:pick ($a->".id") 1 10]\"  [ area=$($a->"packets") label=\"$($a->"chain") $($a->"action")\" tooltip=\"$($a->"comment")\" fontsize=$fontsize  fillcolor=$color $extra ]"
}     
:put "}
[/graphviz]" 
}
