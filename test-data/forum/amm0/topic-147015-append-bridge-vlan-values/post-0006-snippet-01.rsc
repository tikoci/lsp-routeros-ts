# Source: https://forum.mikrotik.com/t/append-bridge-vlan-values/147015/6
# Topic: Append Bridge vlan values
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global mktrunk do={
        :local bvid [/interface/bridge/vlan find dynamic=no vlan-ids=[:if ([:len [:find $"vlan-ids" $1]]) do={:return $"vlan-ids"}]]
        :if ([:len $bvid]=0) do={
            :set bvid [/interface/bridge/vlan add vlan-ids=$1 comment="added by $0" bridge=[/interface/bridge/find vlan-filtering=yes disabled=no]] 
        }
        /interface/bridge/vlan set $bvid tagged=([get $bvid tagged],$2)
    }

 :global rmtrunk do={
        :local bvid [/interface/bridge/vlan find dynamic=no vlan-ids=[:if ([:len [:find $"vlan-ids" $1]]) do={:return $"vlan-ids"}]]
        :local orig [/interface/bridge/vlan get $bvid tagged] 
        :local final [:toarray ""]
        :foreach i in=$orig do={ :if ($i != "$2") do={:set final ($final, $i)} }
        /interface/bridge/vlan set $bvid tagged=$final
        # optional, if there are no more tagged or untagged ports, remove bridge vlan itself        
        :if (([:len [/interface/bridge/vlan get $bvid tagged]]=0) and ([:len [/interface/bridge/vlan get $bvid untagged]]=0)) do={
            /interface/bridge/vlan remove $bvid
        }
        # while mktrunk could take an array of interface, rmtrunk must be a single interface in $2 
 }

# create
    $mktrunk 123 ether4
# update
    $mktrunk 123 ether5
# remove
    $rmtrunk 123 ether5
# note: array is only support on mktrunk, since it was automatic
    $mktrunk 123 ("ether5","ether6")
# but rmtrunk does NOT accept an array and will not find/remove anything
