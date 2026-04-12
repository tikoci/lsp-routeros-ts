# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/15
# Post author: @rextended
# Extracted from: code-block

{
:local source    10.31.42.56/16

:local ip        [:toip [:pick $source 0 [:find $source "/"]]]
:local prefix    [:tonum [:pick $source ([:find $source "/"] + 1) [:len $source]]]
:local submask   (255.255.255.255<<(32 - $prefix))
:local addrspace (~$submask)
:local totip     ([:tonum $addrspace] + 1)
:local network   ($ip & $submask)
:local broadcast ($ip | $addrspace)
:local first     (($network     + 1) - ($prefix / 31))
:local last      (($broadcast   - 1) + ($prefix / 31))
:local usable    (($last - $network) + ($prefix / 31))
:put "       Source: $source"
:put "           IP: $ip"
:put "Subnet Prefix: $prefix"
:put "  Subnet Mask: $submask"
:put "Address Space: $addrspace"
:put "    Total IPs: $totip"
:put "  Network* IP: $network"
:put "Broadcast* IP: $broadcast"
:put "    First* IP: $first"
:put "     Last* IP: $last"
:put "  Usable* IPs: $usable"
}
