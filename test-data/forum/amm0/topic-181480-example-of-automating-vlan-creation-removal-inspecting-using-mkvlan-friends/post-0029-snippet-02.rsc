# Source: https://forum.mikrotik.com/t/example-of-automating-vlan-creation-removal-inspecting-using-mkvlan-friends/181480/29
# Topic: 🧐 example of automating VLAN creation/removal/inspecting using $mkvlan & friends...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# for array output - \$prettyprint
:global prettyprint do={
    :if ([:typeof $1]="nothing") do={
        :put "usage: $0 <data> - print provided <data>, including arrays, in a pretty format"
        :put "example: $0 {\"num\"=1;\"str\"=\"text\";\"float\"=\"0.123\"}"
        :error ""
    }
    :local jsonstr [:serialize to=json options=json.pretty $1]
    :if ($2 = "as-value") do={ :return $jsonstr } else={ :put $jsonstr }  
}

# logging helpers - \$l0g
:global debug
:global "l0g-no-put"
:global "l0g-no-log"
:global l0g do={
    :global prettyprint
    :local lvl $level
    :if ($lvl~"(debug|info|warning|error)") do={} else={:set lvl "info"}
    :local msg "$[:tostr $1]"
    :if ([:typeof $2]!="nothing") do={:set msg "$msg\r\n$[$prettyprint $2 as-value]"} 
    :if ($"l0g-no-log") do={} else={
        :if ($lvl="debug") do={/log debug $msg}
        :if ($lvl="info") do={/log info $msg}
        :if ($lvl="warning") do={/log warning $msg}
        :if ($lvl="error") do={/log error $msg}
    }
    :if ($"l0g-no-put") do={} else={:put $msg}
}
# extra help just for dending debug
:global l0gd do={
    :global debug
    :global l0g
    :if ($debug) do={
        $l0g $1 $2 level=debug
    }
}

# coloring helper
:global c0lor do={
    :global c0lor
    :local helptext "\
    \r\n \$c0lor
    \r\n  generates ANSI codes that can be used in a string to add colorized text\
    \r\n     \$c0lor <text-color> [inverse=yes] [[bold=yes]|[dim=yes]]"    
    # handle 8-bit color names
    :local lookupcolor8 do={
        :local color8 {
            black={30;40};
            red={31;41};
            green={32;42};
            yellow={33;43};
            blue={34;44};
            magenta={35;45};
            cyan={36;46};
            white={37;47};
            "no-style"={39;49};
            reset={0;0};
            "bright-black"={90;0};
        }
        :if ($1 = "as-array") do={:return $color8}
        :if ([:typeof ($color8->$1)]="array") do={
            :return ($color8->$1) 
        } else={
            :return [:nothing]
        }
    }
    :if ($1 = "color") do={
        :if ([:typeof $2] = "str") do={
            :local ccode [$lookupcolor8 $2]
            :if ([:len $ccode] > 0) do={
                :put $ccode 
                :return [:nothing]
            } else={$c0lor colors}
        } else={$c0lor colors}
    }
    :if ($1 = "colors") do={
        :put "\t <color>\t\t $[$c0lor no-style inverse=yes]inverse=yes$[$c0lor reset]\t\t $[$c0lor no-style bold=yes]bold=yes$[$c0lor reset]\t\t $[$c0lor no-style dim=yes]dim=yes$[$c0lor reset]"
        :foreach k,v in=[$lookupcolor8 as-array] do={
            :local ntabs "\t"
            :if ([:len $k] <  8 ) do={
                :set ntabs "\t\t"
            } 
            :put "\t$[$c0lor $k]$k$[$c0lor reset]$ntabs$[$c0lor $k inverse=yes]\t$k$[$c0lor reset]\t$[$c0lor $k bold=yes]$ntabs$k$[$c0lor reset]\t$[$c0lor $k dim=yes]$ntabs$k$[$c0lor reset]"
       } 
       :return [:nothing]
    }
    :if ($1 = "help") do={
        :put $helptext
        :return [:nothing]
    }
    # set default colors
    # sets default to no-style - :local c8str {mod="";fg="$([$lookupcolor8 no-style]->0)";bg="$([$lookupcolor8 no-style]->1)"}
    :local c8str {mod="";fg="";bg=""}
    # if the color name is the 1st arg, make the the foreground color
    :if ([:typeof [$lookupcolor8 $1]] = "array") do={
        :set ($c8str->"fg") ([$lookupcolor8 $1]->0)
        :set ($c8str->"bg") ([$lookupcolor8 "no-style"]->1)
    } 
    # set the modifier...
    # hidden= 
    :if ($hidden="yes") do={
        :set ($c8str->"mod") "8"
    } else={
        # bold=
        :if ($bold="yes") do={
            :set ($c8str->"mod") "1"
            # set both bold=yes and light=yes? bold wins...
        } else={
            # dim=
            :if ($dim="yes") do={
                :set ($c8str->"mod") "2"
            }
        }        
        # inverse= 
        :if ($inverse="yes") do={
            :if ([:len ($c8str->"mod")]>0) do={ :set ($c8str->"mod") "$($c8str->"mod");"}
            :set ($c8str->"mod") "$($c8str->"mod")7"
        } 
    }
    # if bg= set, apply color  
    :if ([:typeof $bg]="str") do={
        :if ([:typeof [$lookupcolor8 $bg]] = "array") do={
            :set ($c8str->"bg") ([$lookupcolor8 $bg]->1)
        } else={:error "bg=$bg is not a valid color"}
    }
    # build the output
    :local rv "\1B["
    :if ([:len ($c8str->"fg")]>0) do={
        :if ([:len ($c8str->"mod")]>0) do={
            :set rv "$rv$($c8str->"mod");$($c8str->"fg")" 
        } else={
            :set rv "$rv$($c8str->"fg")" 
        }
    } else={
        :set rv "$rv$($c8str->"mod")"
    }
    :if ([:len ($c8str->"bg")]>0) do={
        :if ([:len $rv]>2) do={
            :set rv "$rv;$($c8str->"bg")"
        }

    }
    :set rv "$($rv)m"
    # if debug=yes, show the ANSI codes instead
    :if ($debug = "yes") do={
        :return [:put "\\1B[$[:pick $rv 2 80]"]
    }
    # if the 2nd arg is text, or text= set, 
    :local ltext $2
    :if ([:typeof $text]="str") do={
        :set ltext $text
    }
    :if ([:typeof $ltext] = "str") do={
        :return [:put "$rv$2$[$c0lor reset]"]
    }
    :return $rv    
}


:global pvid2array do={
    # autovlanstyle - overrides the default IP addressing scheme,
    #                 valid values: "bytes", "bytes10", or "split10"
    :global autovlanstyle
    #       i.e. by adding a valid style to end of above, like this: 
    # :global autovlanstyle "split10"

    # determine "addressing style" from \$autovlanstyle - default bytes
    :local schema "bytes"
    :if ([:typeof $style] = "str") do={
        :if ($style~"(bytes|bytes10|split10)") do={} else={
            :error "$0 style= must be either bytes | bytes10 | split10 "
        }
        :set schema $style
    } 
    :if ([:typeof $autovlanstyle] = "str") do={
        :if ($autovlanstyle~"(bytes|bytes10|split10)") do={
            :set schema $autovlanstyle
        }
    }
    # process args 
    :local vlanid [:tonum $1]
        # check it PVID is valid
    :if ([:typeof $vlanid] != "num" || $vlanid < 2 || $vlanid > 4094) do={
        :error "PVID must be valid as first argument to command function" 
    }
    # find the bridge interface
    :local bridgeid [/interface bridge find vlan-filtering=yes]
    :if ([:len $bridgeid] != 1) do={
        :error "A bridge with vlan-filtering=yes is required, and there can be only one for this script."
    }
    # uses :convert to break pvid into array with 2 elements between 0-256
    :local vlanbytes [:convert from=num to=byte-array $vlanid]  
    :local lowbits ($vlanbytes->0)
    :local highbits ($vlanbytes->1)
        # NOTE: UGLY workaround for MIPSBE/other, detected when we don't get two parts from the vlan-id
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
    # determine the leading 3 octets, based on the "schema" 
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
        # map pvid into /24 with 10.<lowbits>.<highbits>.0/24
        :if ($vlanid < 256) do={
            :set ipprefix "10.0.$vlanid"
        } else={
            :set ipprefix "10.$($lowbits+1).$highbits" 
        }
    }
    :if ($schema = "split10") do={
        # map pvid into 10.pvid[3]pvid[2].pvid[1].pvid[0] using ASCII chars in pvid 
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

    # Ideally it be able to do a "export where" to show the code, which kinda works 
    # But for dhcp-server here, but elsewhere too, it exports all children despite the "where" 
    # Mikrotik confirmed it a known bug to be fixed, no ETA.  
    # ":grep" used to strip comments from "export where" since it be duplicate when doing multiple exports
    #     [[:parse ":grep pattern=\"^/\" script={:grep pattern=\"lease-time\" script={/ip/dhcp-server/export terse where comment=\"$tag\"}} "]]
    #     [[:parse ":grep pattern=\"^/\" script={/ip/dhcp-server/network/export terse where comment=\"$tag\"} "]]

    :return [$prettyprint $json]
}

:global lsbridge do={
    :global l0g
    :global l0gd
    :global c0lor
    :global prettyprint

    $l0gd "hello?"

  ### PROCESS ARGS 
        # help
    :if ("$1" = "help") do={
        :error "$0 [ports|vlans] [show-ids] [as-value] [trim=yes*|no] [color=yes*|no]"
    }
        # display/table options
    :local showtables [:toarray ""] 
    :if (" $1 $2 $3 $4 $5 $6 $7 $8 "  ~ " vlan | vlans ") do={
        :set showtables ($showtables,"vlans")
    }
    :if (" $1 $2 $3 $4 $5 $6 $7 $8 "  ~ " port | ports ") do={
        :set showtables ($showtables,"ports")
    }
    :local shouldtrim true
    :if ("$trim" ~ "no") do={
        :set shouldtrim false 
    }
    :local usecolor true
    :if ("$color" ~ "no") do={
        :set usecolor false 
    }
        # output options
    :if ([:len $showtables] = 0) do={
        :set showtables ("ports","vlans") 
    }
    :local showids false 
    :if (" $1 $2 $3 $4 $5 $6 $7 $8 "  ~ " show-id | show-ids ") do={
        :set showids true
    }
        # "classic" to disable output to console
    :local asvalue false 
    :if (" $1 $2 $3 $4 $5 $6 $7 $8 "  ~ " as-value ") do={
        :set asvalue true
    }

  ### MACROS AND HELPER LOCAL FUNCTIONS
    :local flagmap {
        "vlans"={".opts"=[:toarray ""];".flags"=[:toarray ""]};
        "ports"={".opts"=[:toarray ""];".flags"=[:toarray ""]}
    }

    # setcharposition <str> <char> pos=<pos> 
    :local setcharposition do={ 
        :local bytes [:convert to=byte-array $1]
        :local lmin [:tonum $min]
        :local lpos [:tonum $pos]
        #:put "$0 debug setcharposition START - str '$1' char '$2' pos '$lpos'/'$lpos' min '$min'/$lmin"
        :if ($lpos < 1) do={:set $lpos 0} else={:set $lpos [:tonum $lpos]}
        :if ($lpos > $lmin) do={:set lmin $lpos}
        #:put "$0 debug setcharposition fixup - str '$1' char '$2' pos '$lpos' min '$min'"
        :if ([:len [:tostr $2]] = 1) do={
            :set ($bytes->$lpos) [:tonum [:convert to=byte-array [:tostr $2]]]
            #:put "$0 debug setcharposition replace - min '$min' bytes $[:tostr $bytes]"
        }
        :if ($lmin > 0) do={
            :for p from=0 to=([:tonum $lmin]-1) do={
                #:put "$0 debug setcharposition pad enter - $p of $min - char '$[:tostr ($bytes->$p)]' bytes '$[:tostr $bytes]'"
                :if (($bytes->$p)>127 or ($bytes->$p)<32) do={
                    :set ($bytes->$p) 32
                }
            }
        }
        :local rv [:convert from=byte-array $bytes]
        #:put "$0 debug - setcharposition END - $rv $[:len $rv] $[:tostr $bytes]"
        :return $rv
    } 

  ### HEALTH CHECK - require one vlan bridge or bridge=<interface>
    
    :local vlanbridgeids [/interface/bridge find vlan-filtering=yes] 
    :local bridgeid $vlanbridgeids

    # if NO VLAN bridges... see what's going on first, before error'ing
    :if ([:len $vlanbridgeids] = 0) do={
        # check if safe to enable vlan-filtering
        :local allbridgeids [/interface/bridge find]
        :if ([:len $allbridgeids] = 1) do={
            # okay, one bridge only, do any ports NOT use pvid=1?
            :local ispvid1 true
            :local hasports false
            :foreach port in=[/interface/bridge/port/print detail as-value] do={
                :set hasports true
                :if (($port->"pvid") != 1) do={
                   :set ispvid1 false 
                }
            }
            # if no ports, just fail
            :if ($hasports = false) do={
                :error "$0 error - no bridge ports found, manual bridge setup required"
            }
            # if any port has non-default PVID, also fail
            :if ($ispvid1 = false) do={
                :error "$0 error - some bridge ports do not use pvid=1, manual bridge setup required"
            }
            # recommend vlan-filtering=yes - only one bridge, >1 ports, all pvid=1
            :put "\t\tTIP..."
            :put "$0 requires a bridge with vlan-filtering=yes to continue, to enable it:"
            :put "\t/interface/bridge/set $[:tostr $allbridgeids] vlan-filtering=yes"
            :put "\t\t(use at your own risk, likely safe with from a default configuration)"
            :put ""
            :error "$0 error - no bridges with vlan-filtering=yes"
        } else={
            :error "$0 error - no bridges with vlan-filtering=yes, manual bridge setup required"
        }

    }
    :if ([:typeof $bridge]="str") do={
        :local tempbrid [/interface/bridge/find name=$bridge]
        :if ([:len $tempbrid] = 1) do={
            :set bridgeid $tempbrid 
        } else={
            :error "$0 got bridge=$bridge, but bridge name was not found"
        }
    }
    :if ([:len $bridgeid] != 1) do={
        :error "$0 only works with one bridge at a time, use 'bridge=<name>' in args to set one"
    }
    :local bridgename [/interface/bridge get $bridgeid name] 

  ### MAKE VLANS MAP
    # dictionary-of-dictionaries indexed by bridge *vlan-id* & included in output
    :local pvidmap [:toarray ""]

    # start with /interface/bridge/vlan/print 
    :local brports [/interface/bridge/vlan/print detail as-value where bridge=$bridgename] 

    # loop array of vlan entires from print
    :foreach brport in=$brports do={
        
        # loop again... each bridge vlan may have MULTIPLE vlan-ids inside
        :foreach vlanid in=($brport->"vlan-ids") do={

            # initialize vlan-id in pvidmap, if not already
            :local ifid [:tostr [/interface/vlan/find vlan-id=$vlanid interface=$bridgename]]
            :if ([:typeof ($pvidmap->"$vlanid")] != "array") do={ 
                :set ($pvidmap->"$vlanid") {
                    "tagged"=([:toarray ""]);
                    "untagged"=([:toarray ""]);
                    "current-tagged"=([:toarray ""]);
                    "current-untagged"=([:toarray ""]);
                    "dynamic-id"="";
                    "static-id"="";
                    ".ifid"=($ifid);
                    ".brifid"=($brport->".id");
                    ".flags"="";
                    ".opts"="";
                    "flags"=""
                } 
            }
                
            # NOTE: each vlan-id in /inteface/bridge/vlan may have TWO entries:
            #	- dynamiclly created by RouterOS based on some other option
            #	- "statically" (manually) by user config 
            # ...thus we may see same vlan-id TWICE in loop

            # store .id based on if static or dynamic (since there could be BOTH) 
            :if ([/interface/bridge/vlan/get ($brport->".id") dynamic]) do={
                :set ($pvidmap->"$vlanid"->"dynamic-id") (($pvidmap->"$vlanid"->"dynamic-id"),($brport->".id"))
            } else={
                :set ($pvidmap->"$vlanid"->"static-id") ($brport->".id")
            }
            
            # set .flags
                # has dynamic bridge vlan entry (non-standard flag)
            :if ([:len ($pvidmap->"$vlanid"->"dynamic-id")]>0)  do={
                if (($pvidmap->"$vlanid"->".flags")~"d") do={} else={
                    :local posflag [$setcharposition ($pvidmap->"$vlanid"->".flags") pos=2 min=3 "d"]
                    :set ($pvidmap->"$vlanid"->".flags") $posflag
                    :set ($flagmap->"vlans"->".flags"->"d") "MAC-dynamic" 
                }
            }
                # has "static" bridge vlan (non-standard flag)
            :if ([:len ($pvidmap->"$vlanid"->"static-id")]>0) do={
                if (($pvidmap->"$vlanid"->".flags")~"s") do={} else={
                    :local posflag [$setcharposition ($pvidmap->"$vlanid"->".flags") pos=1 min=3 "s"]
                    :set ($pvidmap->"$vlanid"->".flags") $posflag
                    :set ($flagmap->"vlans"->".flags"->"s") "MAC-static" 
                }
            }
                # disabled
            :if ([/interface/bridge/vlan/get ($brport->".id") "disabled"]=true) do={
                :local posflag [$setcharposition ($pvidmap->"$vlanid"->".flags") pos=0 min=3 "X"]
                :set ($pvidmap->"$vlanid"->".flags") $posflag
                :set ($flagmap->"vlans"->".flags"->"X") "MAC-disabled" 
            }
            :set ($pvidmap->"$vlanid"->".flags") [$setcharposition min=3 ($pvidmap->"$vlanid"->".flags")] 

            # set .opts
            :local vopts {
                "disabled"={"x";1};
                "mvrp"={"M";2};
                "running"={"r";0};
                "use-service-tag"={"%";2};
            }
            :foreach a,opt in=$vopts do={
                :if ([:len "$ifid"] > 0) do={
                    :if ([/interface/vlan/get $ifid $a]=true) do={
                        :local posflag [$setcharposition ($pvidmap->"$vlanid"->".opts") pos=($opt->1) min=[:len $vopts] ($opt->0)]
                        :set ($pvidmap->"$vlanid"->".opts") $posflag
                        :set ($flagmap->"vlans"->".opts"->($opt->0)) "IP-$a" 				
                    }
                }
            }
            :set ($pvidmap->"$vlanid"->".opts") [$setcharposition min=[:len $vopts] ($pvidmap->"$vlanid"->".opts")] 

            # merge .flages and .opts into flags in map
            :set ($pvidmap->"$vlanid"->"flags") (($pvidmap->"$vlanid"->".flags").($pvidmap->"$vlanid"->".opts"))	
    
            # store interfaces in "pvidmap"
            :set ($pvidmap->"$vlanid"->"tagged") (($pvidmap->"$vlanid"->"tagged"),($brport->"tagged"))
            :set ($pvidmap->"$vlanid"->"untagged") (($pvidmap->"$vlanid"->"untagged"),($brport->"untagged"))
            :set ($pvidmap->"$vlanid"->"current-tagged") (($pvidmap->"$vlanid"->"current-tagged"),($brport->"current-tagged"))
            :set ($pvidmap->"$vlanid"->"current-untagged") (($pvidmap->"$vlanid"->"current-untagged"),($brport->"current-untagged"))
        }
    }

  ### MAKE PORTS MAP
    # dictionary-of-dictionaries indexed by bridge *ports* & included in output
    :local portmap [:toarray ""] 

    # start with VLANS MAP (pvidmap) first to build the "portmap"
    :foreach vid,conf in=$pvidmap do={
        # using tag/untag attributes "portmap" 
        :foreach attr in=("tagged","untagged","current-tagged","current-untagged") do={
            :foreach iface in=($conf->"$attr") do={
                # create if portmap entry for interface, if missing
                :if ([:typeof ($portmap->"$iface")]!="array") do={ :set ($portmap->"$iface") [:toarray ""] }
                # copy data from pvidmap into portmap 
                :set ($portmap->"$iface"->"$attr") (($portmap->"$iface"->"$attr"),$vid)  
            }
        }
    }

    # NOTE: "portmap" is initially created using the "tagged"/etc in /interface/bridge/vlan
    #	but pvid= & others should be included from /interface/bridge/port
    #   so this modifies BOTH "pvidmap" and "portmap"
    
    # start with /interface/bridge/port 
    :local arrports [/interface/bridge/port/find bridge=$bridgename]

    # loop though all bridge ports
    :foreach pid in=$arrports do={
        :local pattr [/interface/bridge/port/get $pid]
        :local lpvid [:tostr ($pattr->"pvid")]

            # add ports not already found 
        :if ([:typeof ($portmap->"$($pattr->"interface")")] != "array") do={
            :set ($portmap->"$($pattr->"interface")") [:toarray ""] 
            :foreach attr in=("tagged","untagged","current-tagged","current-untagged","pvids") do={
                :set ($portmap->"$($pattr->"interface")"->"$attr") [:toarray ""]	
            }
        } 
        :set ($portmap->"$($pattr->"interface")"->"untagged") (($portmap->"$($pattr->"interface")"->"untagged"),$lpvid)
        :set ($portmap->"$($pattr->"interface")"->"pvids") (($portmap->"$($pattr->"interface")"->"pvids"),$lpvid)	
        # NOTE: below modifies "pvidmap" here, since pvid= only on bridge ports
        #       in order to correctly identify the PVID in the "pvidmap"

            # also add pvid= to VLANS map ("pvidmap")
        :if ([:typeof ($pvidmap->"$lpvid")] != "array") do={
            :set ($pvidmap->"$lpvid") [:toarray ""] 
            :foreach attr in=("tagged","untagged","current-tagged","current-untagged","pvids") do={
                :set ($pvidmap->"$lpvid"->"$attr") [:toarray ""]	
            }
        }
        :set ($pvidmap->"$lpvid"->"untagged") (($pvidmap->"$lpvid"->"untagged"),($pattr->"interface"))
        :set ($pvidmap->"$lpvid"->"pvids") (($pvidmap->"$lpvid"->"pvids"),($pattr->"interface")) 
    }

    # loop though the generated "portmap", instead of /interface/bridge/port, to fill in more data
    :foreach k,v in=$portmap do={
        # get the portid
        :local portid [/interface/bridge/port/find interface=$k bridge=$bridgename]
        # NOTE: could be the "mysterious" bridge "port", which is not a /interface/bridge/port
        #	but /interface/bridge itself will have VLAN attributes there, not in ports...
            # storage for "port" attributes, which could be the bridge interface's attributes (not "port")
        :local portattrs [:toarray ""]
            # depending on if bridge port, get the port's vlan attributes
        :local isbridge false
        :if ([:len $portid] != 1) do={
            # must be a bridge?
            # TODO: check if is actually bridge & handle if like non-existant >1
            :set portid $bridgeid
            :set isbridge true
            :set portattrs [/interface/bridge/get $portid]
        } else={
            # get all bridge port attributes
            :set portattrs [/interface/bridge/port/get $portid]
        }
        # portid should be a string (TODO: check if needed)
        :set portid [:tostr $portid]
        # store interface ids in "portmap"
        :set ($portmap->"$k"->".ifid") "$[:tostr [/interface/find name="$k"]]"
        :set ($portmap->"$k"->".brifid") $portid
        # status to .flags
        :local attr2flags {
            "disabled"={"X";0};
            "dynamic"={"D";2};
            "inactive"={"I";1};
            "hw-offload"={"H";3}
        }
        :foreach a,opt in=$attr2flags do={
            :if (($portattrs->"$a")=true) do={
                :local posflag [$setcharposition ($portmap->"$k"->".flags") pos=($opt->1) min=4 ($opt->0)]
                :set ($portmap->"$k"->".flags") $posflag
                :local fname "MAC-$a"
                :if ($a="hw-offload") do={ :set fname "$a"} 
                :set ($flagmap->"ports"->".flags"->($opt->0)) $fname
            }
        }
        :set ($portmap->"$k"->".flags") [$setcharposition min=4 ($portmap->"$k"->".flags")] 
        # frame-types to .opts indicators 
        :local fts {
            "admit-all"={"*";2;"admit all"};
            "admit-only-untagged-and-priority-tagged"={"-";2;"untagged only"};
            "admit-only-vlan-tagged"={"=";2;"only tagged"}
        }
        # NOTE: but only if ingress-filtering is enabled,
        # as frame-types does not apply otherwise so don't show
        :if (($portattrs->"ingress-filtering")=true) do={
            :foreach ft,opt in=$fts do={
                :if (($portattrs->"frame-types")=$ft) do={
                    :set ($portmap->"$k"->".opts") [$setcharposition ($portmap->"$k"->".opts") pos=($opt->1) min=3 ($opt->0)] 
                    :set ($flagmap->"ports"->".opts"->"|$($opt->0)") ($opt->2) 				
                }			
            }
        }
        # vlan filtering/status bools to .opts
        :local vis {
            "ingress-filtering"={"|";1};
            "tag-stacking"={"%";0}
        }
        :foreach vi,opt in=$vis do={
            :if (($portattrs->"$vi")=true) do={
                :set ($portmap->"$k"->".opts") [$setcharposition ($portmap->"$k"->".opts") pos=($opt->1) min=3 ($opt->0)]
                :if ($vi != "ingress-filtering") do={
                    # ingress-filtering flag is included with frame-type, 
                    # since you cannot have one without the other - to save space in output
                    :set ($flagmap->"ports"->".opts"->($opt->0)) $vi
                }				
            }
        }
        :set ($portmap->"$k"->".opts") [$setcharposition min=3 ($portmap->"$k"->".opts")] 
        :set ($portmap->"$k"->"flags") (($portmap->"$k"->".flags").($portmap->"$k"->".opts"))	
    }

    $l0gd ("$0 debug - PORTS:$[:len $portmap] VLANIDS: $[:len $pvidmap]")

 ### MAKE COLUMN HEADERS FOR VLANS AND PORTS TABLES
    # generate column "views" and create output array
        # by ports
    :local listports [:toarray ""]
    :foreach k,v in=$portmap do={:set listports ($listports,$k)}
        # by vlans
    :local listvlanids [:toarray ""]
    :foreach a,v in=$pvidmap do={:set listvlanids ($listvlanids,$a)}
            # sort the "by vlan" so its numerical - not easy...
                # add leading zeros
    :foreach i,x in=$listvlanids do={
        :while ([:len ($listvlanids->$i)]!=4) do={
            :set ($listvlanids->$i) "0$($listvlanids->$i)"
        }
    }
           # by making it map, it sorted by RouterOS
    :local fakemap [:toarray ""]
    :foreach m in=$listvlanids do={:set ($fakemap->"$m") [:tonum $m]}
            # now unwind the "fake" map into the list
    :set listvlanids [:toarray ""]
    :foreach k,vid in=$fakemap do={:set $listvlanids ($listvlanids,$vid)}
            # ...done sort vlan id's numbers numberically...

 ### "MAKEROW" FUNCTION - essentially makes a "PivotTable" using a maps
    # makerow - returns simple list, in column order from above, for BOTH MAPS 
    :local makerow do={
        :local rv [:toarray ""]
        # loop over the map, to create plain list of untag/tag status from provided map
        :foreach q,prt in=$zmap do={
            :local rp [:toarray ""]
            :foreach ivp,vid in=($zlist) do={
                # determine U / u / T / t from provided entry in map 
                :foreach torc in=("tagged","untagged") do={
                    :if ([:typeof [:find ($prt->"$torc") $vid]]="num") do={
                        :if (([:typeof [:find ($prt->"current-$torc") $vid]]="num")) do={
                            :set ($rp->$ivp) [:tostr [:convert transform=uc [:tostr [:pick $torc 0 1]]]]
                        } else={
                            :set ($rp->$ivp) [:tostr [:pick $torc 0 1]]
                        }
                    } else={
                        # nothing mean port is NOT on the VLAN
                        :if ([:typeof ($rp->$ivp)] != "str") do={
                            :set ($rp->$ivp) [:nothing]
                        }
                    }
                }
                # handle PVID "+"
                :if ([:typeof [:find ($prt->"pvids") $vid]]="num") do={
                    :set ($rp->$ivp) (($rp->$ivp)."+")	
                }
            }
            :set ($rv->"$q") $rp 
        }
        :return $rv
    }

 ### USING ROWS, DETERMINE HYBIRD, TRUNK, OR ACCESS PORTS
        # use above to resolving the tag/untag flags & add it as a "row" list in both maps  
    :foreach p,portrow in=[$makerow zmap=$portmap zlist=$listvlanids rmap=$pvidmap] do={
        :set ($portmap->"$p"->"row") $portrow
        :set ($portmap->"$p"->".type") ""
        :foreach r in=$portrow do={
            :if ([:len $r] > 0) do={
                :if ($r~"(U|u)") do={
                    :if (($portmap->"$p"->".type") ~ "(trunk|hybrid)") do={
                        :set ($portmap->"$p"->".type") "hybrid"
                    } else={
                        :set ($portmap->"$p"->".type") "access"
                    }
                }
                :if ($r~"(T|t)") do={
                    :if (($portmap->"$p"->".type") ~ "(access|hybrid)") do={
                        :set ($portmap->"$p"->".type") "hybrid"
                    } else={
                        :set ($portmap->"$p"->".type") "trunk"
                    }
                }
            }
        }
    }
        # same as above, for "pvidrow" (TODO: should refactor)
    :foreach v,pvidrow in=[$makerow zmap=$pvidmap zlist=$listports rmap=$portmap] do={
        :set ($pvidmap->"$v"->"row") $pvidrow
        :set ($pvidmap->"$v"->".type") ""
        :foreach r in=$pvidrow do={
            :if ([:len $r] > 0) do={
                :if ($r~"U|u") do={
                    :if (($pvidmap->"$v"->".type") ~ "(trunk|hybrid)") do={
                        :set ($pvidmap->"$v"->".type") "hybrid"
                    } else={
                        :set ($pvidmap->"$v"->".type") "access"
                    }
                }
                :if ($r~"T|t") do={
                    :if (($pvidmap->"$v"->".type") ~ "(access|hybrid)") do={
                        :set ($pvidmap->"$v"->".type") "hybrid"
                    } else={
                        :set ($pvidmap->"$v"->".type") "trunk"
                    }
                }
            }
        }
    }

 ### FLATTEN ALL MAPS FOR DISPLAY
    # determine output columns
    :if ($showids = true) do={}
    :local precols (".ifid",".brifid","flags")

    # finally "flatten" maps for use in display/CSV into ->.table
    :local tablegen {
        "ports"={"fmap"=$portmap;"cols"=$listvlanids;"rmap"=$pvidmap;"rows"=[:toarray ""]};
        "vlans"={"fmap"=$pvidmap;"cols"=$listports;"rmap"=$portmap;"rows"=[:toarray ""]}
    }
    :foreach tablename,opts in=$tablegen do={
        :local frows [:toarray ""]
        :local fmap ($opts->"fmap")
        :local cols ($opts->"cols")
        :local rmap ($opts->"rmap")

        # helper to shorten ifnames to 8 chars to display as table in terminal
        :local trimcell do={:return $1}
        :if ($shouldtrim = true) do={
            :set trimcell do={
                :if ([:len $1] > 8) do={
                    :return "$[:pick $1 0 3]~$[:pick $1 ([:len $1]-3) [:len $1]]"
                }
                :return $1
            }
        }

        # trim colum names
        :local scols [:toarray ""]
        :foreach c in=$cols do={ 
            :set scols ($scols,[$trimcell $c]) 
        }

        # update column header colors
        :foreach i,c in=$scols do={
            :local v ($rmap->"$[:tostr $c]")
            :local tcolor "no-style"
            :if (($v->".type")="hybrid") do={:set tcolor "cyan"}
            :if (($v->".type")="trunk") do={:set tcolor "magenta"}
            :if (($v->".type")="access") do={:set tcolor "green"}
            :if ([:len ($v->".brifid")] = 0) do={
                :set tcolor "yellow"
            }
            :set ($scols->$i) "$[$c0lor $tcolor bold=yes]$c$[$c0lor reset]"
        }
        
        # build the flat table            
        :foreach k,v in=$fmap do={
            :local frow [:toarray ""]
            :local mrow ($v->"row")
            :set frow [:toarray ""]
            :foreach i,pcol in=$precols do={
                :set ($frow->$i) ($v->"$pcol")
                :local dim no
                :local pcolor no-style
                :if ($pcol~"id\$") do={:set dim yes; :set pcolor blue}
                :if ($pcol="flags") do={
                    :local fansi "" 
                    :foreach j,f in=[:convert to=byte-array ($v->"flags")] do={
                        :local c [:convert from=byte-array ({$f})]
                        :if ($c~"H|r") do={
                            :set fansi ($fansi.[$c0lor green dim=yes].$c.[$c0lor reset])
                        } else={
                        :if ($c~"d") do={
                            :set fansi ($fansi.[$c0lor yellow dim=yes].$c.[$c0lor reset])
                        } else={
                        :if ($c~"X|x|I") do={
                            :set fansi ($fansi.[$c0lor red bold=yes].$c.[$c0lor reset])
                        } else={
                            :set fansi ($fansi.$c)
                        }}}
                    }
                    :set ($frow->$i) $fansi 
                } else={
                    :set ($frow->$i) "$[$c0lor $pcolor dim=$dim]$($v->"$pcol")$[$c0lor reset]"
                }
            }
            :if ($usecolor = true) do={}
            :foreach i,m in=$mrow do={
                :local color "no-style"
                :local bold "no"
                :local inv "no"
                :local bg "no-style"
                :if ($m~"(U|u)") do={:set color "green"}
                :if ($m~"(T|t)") do={:set color "magenta"; :set bg "white"}
                :if ($m~"(U|T)") do={:set bold "yes"}
                :if ($m~"(U|u|T|t)") do={:set inv "yes"}
                :set ($mrow->$i) " $[$c0lor $color bg=$bg inverse=$inv bold=$bold] $[$setcharposition $m min=2]$[$c0lor reset]"
            } 
            :local tcolor "no-style"
            :if (($v->".type")="hybrid") do={:set tcolor "cyan"}
            :if (($v->".type")="trunk") do={:set tcolor "magenta";}
            :if (($v->".type")="access") do={:set tcolor "green"}
            :if ([:len ($v->".brifid")] = 0) do={
                # must be the mysterious bridge port, since it is NOT a /interface/bridge/port
                :set tcolor "yellow"
            }
            :set frow ($frow,"$[$c0lor $tcolor bold=yes]$[$trimcell $k]$[$c0lor reset]",$mrow)
            :set frows ($frows,{$frow})
        }
        :if ($addtableheaders = true) do={}
        # add footers
        $l0gd [$prettyprint $flagmap as-value]
        :local footer ([$c0lor inverse=no].[$c0lor cyan bold=yes]."  Flags:  ".[$c0lor no-style])
        :foreach fall in=(".opts",".flags") do={
            :foreach f,t in=($flagmap->"$tablename"->"$fall") do={
                :set footer ($footer."  ".[$c0lor green bold=yes].$f." ".[$c0lor no-style dim=yes].$t)
            }
        }

        :local header ($precols,"$[$c0lor bold=yes]$tablename$[$c0lor reset]",$scols)
        # set table header/footer for output
        :set ($tablegen->"$tablename"->".header") $header
        :set ($tablegen->"$tablename"->".footer") $footer
        
        # combine table for output
        :set frows ({$header},$frows)
        
        # also update the rows in tablegen array
        :set ($tablegen->"$tablename"->"rows") $frows
    }

 ### CREATE OUTPUT ARRAY FROM LOCAL VARIABLES

    # setup output, including flat vlan/port tables
    :local out [:toarray ""]
    :set ($out->"ports") $portmap 
    :set ($out->"vlans") $pvidmap 

    # add "columns", which store the vlanid/port name indexed same as rows
    :set ($out->".cols") [:toarray ""] 
    :set ($out->".cols"->"ports") $listports 
    :set ($out->".cols"->"vlans") $listvlanids
    :set ($out->".cols"->".pre") $precols 

    # store generated tables (TODO: should be arg to control)
    :set ($out->".tables") [:toarray ""]
    :set ($out->".tables"->"ports") ($tablegen->"ports"->"rows")
    :set ($out->".tables"->"vlans") ($tablegen->"vlans"->"rows")

    # store the headers/footer
    :set ($out->".header"->"ports") ($tablegen->"ports"".header")
    :set ($out->".header"->"vlans") ($tablegen->"vlans"->".header")
    :set ($out->".footer"->"ports") ($tablegen->"ports"->".footer")
    :set ($out->".footer"->"vlans") ($tablegen->"vlans"->".footer")

    # handle as-value
    :if ($asvalue) do={
        # do nothing - since actually always return the out array
    } else={
        # ... output are "pretty" tables
        :global catbridge
        $catbridge bridge=$bridgename
        :foreach tbl in=$showtables do={
            # generate header line
            :local header " $tbl "
                # calculate heder length
                # 	NOTE: port cols uses vlans, & vice-versa... so use "inverse" table to calc [:len]
            :local revrow "vlans"
            :if ($tbl="vlans") do={:set revrow "ports"}
                # add spaces (8 chars are tab break; name is not in .pre nor .cols, so +1)
            :local headerlen (([:len ($out->".cols"->".pre")]+[:len ($out->".cols"->"$revrow")]+1)*8)
            :local nspaces ($headerlen-[:len $header])
            :for c from=0 to=$nspaces do={ :set $header ($header." ") }
                # build header with spaces and colorize if needed
            :set header ([$c0lor cyan bold=yes inverse=yes].[:convert transform=uc $header].[$c0lor reset]) 
            :put $header 
            # output rows for table
            :local map ($out->".tables"->"$tbl")
            :foreach row in=$map do={
                :put [:serialize to=dsv delimiter="\t" $row]
            }
            :put ($out->".footer"->"$tbl")
        }
        :put ([$c0lor cyan bold=yes]." Colors:  ".[$c0lor reset].[$c0lor red]."disabled ".[$c0lor green]."enabled  ".[$c0lor cyan bold=yes]."\t Ports:  ".[$c0lor reset].[$c0lor magenta]."trunk ".[$c0lor cyan]."hybrid ".[$c0lor green]."access  ".[$c0lor bold=yes green]."+ ".[$c0lor reset].[$c0lor gray]."pvid".[$c0lor reset])    
    }
    :return $out
}


:global catbridge do={
    :global c0lor
    :global l0gd

    # check for c0lor, if none disable ANSI codes
    #:if ([:typeof $c0lor]="nothing") do={
    #    :put "  No \$c0lor found.  See http://forum.mikrotik.com on how to add \$c0lor function"
    #    :set c0lor do={return ""}
    #}
    # find bridge to cat
    :local bridgeid
    :local bridgename $name
    :if ([:typeof $bridgename]!="str") do={
        :set bridgeid [/interface/bridge/find vlan-filtering=yes disabled=no]
    } else={
        :set bridgeid [/interface/bridge/find name=$bridgename] 
    } 
    # handles errors and help
    :local helptext "$0 [bridge=<bridge-name>] - colorized display of bridge settings\r\n\t(default: bridge= first vlan-filtering=yes disabled=no bridge)"
    :if ($1="help") do={
        :error $helptext
    }
    :if ([:len $bridgeid]!=1) do={
        :put $helptext
        :error "error - could not find bridge, should be one but got '$[:tostr $bridgeid]'"
            
    }
    # get bridge settings
    :local brget [/interface/bridge/get $bridgeid]
    
    # store results in array first
    :local rv [:toarray ""]

    # mapping attributes to categories
    :local bridgemap {
        { "";{"running";"disabled";"dynamic";"name";".id"}}
        { "";{"comment"}}
        { "mac";{"mac-address";"auto-mac";"admin-mac"}};
        { "ether";{"ether-type";"fast-forward";"arp";"arp-timeout"}};
        { "mtu";{"actual-mtu";"mtu";"l2mtu"}};
        { "vlan";{"vlan-filtering";"pvid";"ingress-filtering";"frame-types";"mvrp"}};
        { "stp";{"protocol-mode";"priority";"port-cost-mode";""}};
        { "dhcp";{"dhcp-snooping";"add-dhcp-option82"}};
        { "igmp";{"igmp-snooping";"igmp-version";"multicast-router";"multicast-querier";"mld-version"}};
    }
    :foreach bridgeitem in=$bridgemap do={
        :local groupname ($bridgeitem->0)
        :local attrs ($bridgeitem->1)
        
        # build map based bridgemap array, and colorize if possible
        :local oline ""
        :foreach attr in=$attrs do={
            :local val ($brget->$attr)
            :local oval $val
            :local oattr $attr
            :local usegeneric true
            :local colorval cyan
            :local colorattr no-style
            # handle fixups
             :if ($oval="enabled") do={
                # cause "enabled" to be same as another bool
                :set oval true
            }
            :if ($oval="disabled") do={
                # cause "enabled" to be same as another bool
                :set oval false
            }
            :if ($attr=".id") do={
                :set oval [:tostr $bridgeid]
            }
            :if ($attr~"(running|disabled|dynamic)") do={
                :if ($oval=false) do={
                    :set usegeneric false
                }
                if ($attr~"disabled") do={
                    :set colorval red
                }
                :set oattr [:convert transform=uc $oattr]
            }
            :if ($attr~"(frame-types|mac-address)") do={
                :set oattr ""
            }
            :if ($attr="protocol-mode") do={
                :set oattr ""
                :set colorval magenta
                :set oval [:convert transform=uc $oval] 
            }
            :if ($attr="comment") do={
                :set oattr ""
                :set colorval magenta
                :if ([:len $oval]=0) do={
                    :set usegeneric false
                }
            }
            :if ($attr~"mvrp|arp\$") do={
               :set oattr [:convert transform=uc $oattr] 
            }
            :if ($attr="multicast-router" and $val="temporary-query") do={
                :set oattr ""
                :set colorval green
            }
            :if ($attr="igmp-version") do={
                :set oattr "ver"
            }
            # run styling code 
            :if ($usegeneric) do={
                :local valtype [:typeof $oval]
                :if ($valtype="str") do={
                    :set oline ($oline.[$c0lor no-style dim=yes].$oattr." ".[$c0lor $colorval bold=yes].$oval.[$c0lor reset]."  ")
                }
                :if ($valtype="num") do={
                    :set oline ($oline.[$c0lor no-style dim=yes].$oattr." ".[$c0lor $colorval bold=yes].$oval.[$c0lor reset]."  ")
                }
                :if ($valtype="bool") do={
                    :if ($oval = true) do={
                        :set oline ($oline.[$c0lor green bold=yes].$oattr.[$c0lor reset]."  ")
                    } else={
                        :set oline ($oline.[$c0lor red bold=yes].$oattr.[$c0lor reset]."  ")
                    }
                }
                # array or nothing not handled
                :if ($valtype~"str|num|bool") do={} else={}
            }
        }
        :local line "      $[$c0lor yellow bold=yes]$[:convert transform=uc $groupname]$[$c0lor reset]\t$oline"
        :set rv ($rv,$line)
    }
    :local headerline " BRIDGE "
    :for s from=[:len $headerline] to=77 do={
        :set headerline ($headerline." ") 
    }
    :put ([$c0lor cyan inverse=yes bold=yes].$headerline.[$c0lor reset])
    :foreach r in=$rv do={:put $r}
}


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

:global mkpvid do={
    :local bpvid $1
    :local bpname $2
    /interface/bridge/port set [find interface=$bpname] pvid=$bpvid
}
