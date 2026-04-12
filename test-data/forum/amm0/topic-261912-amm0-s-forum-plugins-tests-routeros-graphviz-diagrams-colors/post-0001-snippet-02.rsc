# Source: https://forum.mikrotik.com/t/amm0s-forum-plugins-tests-routeros-graphviz-diagrams-colors/261912/1
# Topic: Amm0's Forum Plugins Tests — ` ` `routeros & [graphviz] diagrams & colors
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global myname "forum"
/system/identity set name=$myname
:onerror err in={
    /ip/address add interface=ether1 address=169.254.1.1/16
} do={
    :put "address already assigned for $myname"
}
/routing
bgp
evpn print 

{
   :local mybfd [:serialize to=dsv decimator=, options=dsv.remap [bfd print as-value]]
   /file add name="bfd.csv" contents=$mybfd
}
