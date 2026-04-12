# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/15
# Post author: @rextended
# Extracted from: code-block

{
:local sourceip    10.31.42.56
:local sourcesub   255.255.0.0

:local ip        [:toip $sourceip]
:local submask   [:toip $sourcesub]
:local addrspace (~$submask)
:local tempsub   [:tonum $addrspace]
:local prefix    32
:while ($tempsub > 0) do={:set tempsub ($tempsub / 2); :set prefix ($prefix - 1)}
:local totip     ([:tonum $addrspace] + 1)
:local network   ($ip & $submask)
:local broadcast ($ip | $addrspace)
:local first     (($network     + 1) - ($prefix / 31))
:local last      (($broadcast   - 1) + ($prefix / 31))
:local usable    (($last - $network) + ($prefix / 31))
:put "    Source IP: $ip"
:put "  Source Mask: $submask"
:put "Subnet Prefix: $prefix"
:put "Address Space: $addrspace"
:put "    Total IPs: $totip"
:put "  Network* IP: $network"
:put "Broadcast* IP: $broadcast"
:put "    First* IP: $first"
:put "     Last* IP: $last"
:put "  Usable* IPs: $usable"
}
