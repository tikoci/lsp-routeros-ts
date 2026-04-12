# Source: https://forum.mikrotik.com/t/example-of-automating-vlan-creation-removal-inspecting-using-mkvlan-friends/181480/13
# Topic: 🧐 example of automating VLAN creation/removal/inspecting using $mkvlan & friends...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global mkvlan
:global catvlan
:global rmvlan
:global prettyprint 
:global pvid2array
:global autovlanstyle
:set mkvlan
:set catvlan
:set rmvlan
:set prettyprint 
:set pvid2array
:set autovlanstyle
/system/script/run autovlan
$prettyprint [$pvid2array 60]
