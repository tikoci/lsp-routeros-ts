# Source: https://forum.mikrotik.com/t/howto-import-zerotier-members-into-mikrotik-dns-using-zt2dns/173937/4
# Topic: HOWTO:  Import ZeroTier Members into Mikrotik DNS using $ZT2DNS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global get6plane do={
    :local net $network
    :local mem $memberid
    :local ip6prefix "fc"

    # get the "magic" ZT network part of the 6PLANE adddress 
    :local xornet [([:tonum "0x$[:pick $net 8 16]"]^[:tonum "0x$[:pick $net 0 8]"])]
    :local rawnetpart [:convert from=num to=hex [:tonum $xornet]]
    :put "\t\t# debug: network XOR 'magic' - $rawnetpart"
    :put "\t\t# testing: network=ebe7fbd445a53215 should get 2923612609"
    
    # build the IPv6 address prefix as long hexstring, without colons
    :local rawaddr "fc$($rawnetpart)$($memberid)"
    :put "\t\t# debug: combined with memberid - $rawaddr"
    
    # add the IPv6 colons in middle of hex
    :local addrstr ""
    :for i from=0 to=20 step=4 do={
        :set addrstr "$addrstr$[:pick $rawaddr $i ($i+4)]:"
    }
    :put "\t\t# debug: network part with colons - $addrstr"
    
    # convert the str, with ZT default host of ::1
    :local ip6plane [:toip6 "$($addrstr)1"]
    :put "\t\t# info: ZT 6PLANE IPv6 as ip6 type: $ip6plane $[:typeof $ip6plane]"

    # if not an IPv6 type, fail script to find any bugs
    :if ([:typeof $ip6plane]!="ip6") do={:error "stopping!  6PLANE not calculated, using network=$network memberid=$memberid"}

    :return $ip6plane
}

:put [$get6plane network="ebe7fbd445a53215" memberid="078f1823b5"]
