# USER SETTINGS
# autovlanstyle - overrides the default IP addressing scheme,
#                 valid values: "bytes", "bytes10", or "split10"
:global autovlanstyle
#       i.e. by adding a valid style to end of above, like this: 
# :global autovlanstyle "split10"


# FUNCTIONS AND CODE
:global pvid2array do={
    # process formating
    :global autovlanstyle
    :local schema "bytes"
    :if ([:typeof $style] = "str") do={
        :if ($style~"bytes|bytes10|split10") do={} else={
            :error "$0 style= must be either bytes | bytes10 | split10 "
        }
        :set schema $style
    } 
    :if ([:typeof $autovlanstyle] = "str") do={
        :if ($autovlanstyle~"bytes|bytes10|split10") do={
            :set schema $autovlanstyle
        }
    }

    # move first argument to function, the PVID, to a variable
    :local vlanid [:tonum $1]
    
    # check it PVID is valid, if not show help and error (which exits script)
    :if ([:typeof $vlanid] != "num" || $vlanid < 2 || $vlanid > 4094) do={
        :error "PVID must be valid as first argument to command function" 
    }
    
    # find the bridge interface ...
    :local bridgeid [/interface bridge find vlan-filtering=yes]
    :if ([:len $bridgeid] != 1) do={
        :error "A bridge with vlan-filtering=yes is required, and there can be only one for this script."
    }

    # uses :convert to break pvid into array with 2 elements between 0-256
    :local vlanbytes [:convert from=num to=byte-array $vlanid]  
    :local lowbits ($vlanbytes->0)
    :local highbits ($vlanbytes->1)

    # UGLY workaround for MIPSBE/other, detected when we don't get two parts from the vlan-id
    :if ([:len $vlanbytes]>2) do={
        :if ($vlanid > 255) do={
            # even worse workaround, normalize to 8 bytes - ros wrongly trims leading 0
            :if ([:len $vlanbytes]=7) do={ 
                # make it len=8 by pre-pending a 0 - so the swap below is correct
                :set vlanbytes (0,$vlanbytes) 
            }
            # now swap the high and low bytes
            :set lowbits ($vlanbytes->1)
            :set highbits ($vlanbytes->0)  
        } 
        # lowbits is right if under 256
    }

    :local ipprefix "0.0.0"
    :if ($schema = "bytes") do={
        # for pvid below 257, use 192.168.<pvid>.0/24 as base IP prefix
        # for others map pvid into unique /24 with 172.<lowbits+15>.<highbits>.0/24
        :if ($vlanid < 256) do={
            :set ipprefix "192.168.$vlanid"
        } else={
            :set ipprefix "172.$($lowbits + 15).$highbits" 
        }
    }
    :if ($schema = "bytes10") do={
        # map pvid into unique /24 with 10.<lowbits>.<highbits>.0/24
        :if ($vlanid < 256) do={
            :set ipprefix "10.0.$vlanid"
        } else={
            :set ipprefix "10.$($lowbits+1).$highbits" 
        }
    }
    :if ($schema = "split10") do={
        :if ($vlanid < 100) do={
            :set ipprefix "10.0.$vlanid" 
        } else={
            :set ipprefix "10.$[:tonum [:pick $vlanid 0 ([:len $vlanid]-2)]].$[:tonum [:pick $vlanid ([:len $vlanid]-2) [:len $vlanid]]]"
        }
    }

    # now calculate the various "formats" of a prefix for use in other scripts
    :return {
        "vlanid"="$vlanid";
        "basename"="vlan$vlanid";
        "commenttag"="mkvlan $vlanid";
        "vlanbridge"="$[/interface/bridge get $bridgeid name]";
        "ipprefix"="$ipprefix";
        "cidrnet"="$ipprefix.0/24";
        "cidraddr"="$ipprefix.1/24";
        "routerip"="$ipprefix.1"; 
        "dhcppool"="$ipprefix.10-$ipprefix.249"; 
        "dhcpgw"="$ipprefix.1"; 
        "dhcpdns"="$ipprefix.1"
    }
}


:global prettyprint do={
    :if ([:typeof $1]="nothing") do={
        :put "usage: $0 <data> - print provided <data>, including arrays, in a pretty format"
        :put "example: $0 {\"num\"=1;\"str\"=\"text\";\"float\"=\"0.123\"}"
        :error
    }
    :put [:serialize to=json options=json.pretty $1]
    :return $1
}


:global mkvlan do={
    :global pvid2array
    :global mkvlan

    :if ([:typeof [:tonum $1]]="num") do={
        :global mkvlan 
        :return ($mkvlan <%% [$pvid2array [:tonum $1]])
    }

    :put "starting VLAN network creation for $cidrnet using id $vlanid ..."
    
    :put " - adding $basename interface on $vlanbridge using vlan-id=$vlanid"
    /interface vlan add vlan-id=$vlanid interface=$vlanbridge name=$basename comment=$commenttag

    :put " - assigning IP address of $cidraddr for $basename"
    /ip address add interface=$basename address=$cidraddr comment=$commenttag

    :put " - adding IP address pool $dhcppool for DHCP"
    /ip pool add name=$basename ranges=$dhcppool comment=$commenttag

    :put " - adding dhcp-server $basename "
    /ip dhcp-server add address-pool=$basename disabled=no interface=$basename name=$basename comment=$commenttag 

    :put " - adding DHCP /24 network using gateway=$dhcpgw and dns-server=$dhcpdns"
    /ip dhcp-server network add address=$cidrnet gateway=$dhcpgw dns-server=$dhcpdns comment=$commenttag 

    :put " - add VLAN network to interface LAN list"
    :if ([:len [/interface list find name=LAN]] = 1) do={
        /interface list member add list=LAN interface=$basename comment=$commenttag 
    }

    :put " - create FW address-list for VLAN network for $cidrnet"
    /ip firewall address-list add list=$basename address=$cidrnet comment=$commenttag  

    :put " * NOTE: in 7.16+, the VLAN $vlanid is dynamically added to /interface/bridge/vlans with tagged=$vlanbridge "
    :put "         thus making an access port ONLY involves setting pvid=$vlanid on a /interface/bridge/port"
    :put " * EX:   So to make 'ether3' an access point, only the following additional command is:"
    :put "           /interface/bridge/port set [find interface=ether3] pvid=$vlanid frame-types=allow-only-untagged"

    /log info [:put "VLAN network created for $cidrnet for vlan-id=$vlanid"]
}


:global rmvlan do={
    :global pvid2array
    :global rmvlan
    :local tag "INVALID"
    :if ([:typeof [:tonum $1]]="num") do={
        :global rmvlan 
        :return ($rmvlan <%% [$pvid2array [:tonum $1]])
    }
    :if ([:typeof $comment]="str") do={
        :set tag $comment
    } else={
        :if ([:typeof $commenttag]="str") do={
            :set tag $commenttag 
        } else={
            :error "$0 requires with an tag provided by '$0 comment=mytag' or via '($0 <%% [$pvid2array 1001]"
        }
    }

    :put "starting VLAN network removal for comment=$tag"
    :put " - remove $basename interface on $vlanbridge using vlan-id=$vlanid"
    /interface vlan remove [find comment=$tag]

    :put " - remove IP address of $cidraddr for $basename"
    /ip address remove [find comment=$tag]

    :put " - remove IP address pool $dhcppool for DHCP"
    /ip pool remove [find comment=$tag]

    :put " - removing dhcp-server $basename "
    /ip dhcp-server remove [find comment=$tag] 

    :put " - remove DHCP /24 network using gateway=$dhcpgw and dns-server=$dhcpdns"
    /ip dhcp-server network remove [find comment=$tag] 

    :put " - remove VLAN network to interface LAN list"
    /interface list member remove [find comment=$tag] 

    :put " - create FW address-list for VLAN network for $cidrnet"
    /ip firewall address-list remove [find comment=$tag]  

    /log info [:put "VLAN network removed for comment=$tag"]
}



:global catvlan do={
    :global pvid2array
    :global catvlan
    :global prettyprint
    :local tag "INVALID"
    :local json [:toarray ""]
    :if ([:typeof [:tonum $1]]="num") do={
        :return [($catvlan <%% [$pvid2array [:tonum $1]])]
    }
    :if ([:typeof $comment]="str") do={
        :set tag $comment
    } else={
        :if ([:typeof $commenttag]="str") do={
            :set tag $commenttag 
        } else={
            :error "$0 requires with an tag provided by '$0 comment=mytag' or via '($0 <%% [$pvid2array 1001]"
        }
    }

    :set ($json->"/interface/vlan") [/interface vlan print detail as-value where comment=$tag]
    :set ($json->"/ip/address") [/ip address print detail as-value where comment=$tag]
    :set ($json->"/ip/pool") [/ip pool print detail as-value where comment=$tag]
    :set ($json->"/ip/dhcp-server") [/ip dhcp-server print detail as-value where comment=$tag] 
    :set ($json->"/ip/dhcp-server/network") [/ip dhcp-server network print detail as-value where comment=$tag] 
    :set ($json->"/interface/list/member") [/interface list member print detail as-value where comment=$tag]
    :set ($json->"/ip/firewall/address-list") [/ip firewall address-list print detail as-value where comment=$tag] 
    


    # This logic to use "export where" does not work, and causes wierd bug - disabling for now
    #:put "VLAN network config..."
    #:put ""
    #[:parse ":grep pattern=\"^/\" script={/interface/vlan/export terse where comment=\"$tag\"} "];
    #[:parse ":grep pattern=\"^/\" script={/ip/address/export terse where comment=\"$tag\"} "];
    #[:parse ":grep pattern=\"^/\" script={/ip/pool/export terse where comment=\"$tag\"} "];
    #[:parse ":grep pattern=\"^/\" script={:grep pattern=\"lease-time\" script={/ip/dhcp-server/export terse where comment=\"$tag\"}} "];
    #[[:parse ":grep pattern=\"^/\" script={/ip/dhcp-server/network/export terse where comment=\"$tag\"} "]]; 
    #[[:parse ":grep pattern=\"^/\" script={/interface/list/member/export terse where comment=\"$tag\"} "]];
    #[[:parse ":grep pattern=\"^/\" script={/ip firewall address-list/export terse where comment=\"$tag\"} "]]; 
    #:put ""

    :return [$prettyprint $json]
}