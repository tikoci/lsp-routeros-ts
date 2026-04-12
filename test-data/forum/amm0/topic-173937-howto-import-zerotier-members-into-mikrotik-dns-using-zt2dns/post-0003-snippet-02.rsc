# Source: https://forum.mikrotik.com/t/howto-import-zerotier-members-into-mikrotik-dns-using-zt2dns/173937/3
# Topic: HOWTO:  Import ZeroTier Members into Mikrotik DNS using $ZT2DNS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global ZT2DNS do={
    :if ($1="help") do={
        :put "\$ZT2DNS - updates static DNS on Mikrotik from a ZeroTier network"
        :put "  usage: \$ZT2DNS token=<api_token> [network=<network_id>] [suffix=<dns_domain>]"
        :put "     <api_token> is 'API Access Tokens' from https://my.zerotier.com/account "
        :put "     <network_id> is ZeroTier network ID to use. Default: first running ZT interface"
        :put "     <suffix> added to name= in DNS entries, must include any leading dot. Default: \"\""
        :put "  advanced usage: (all optional)"
        :put "     replace=<yes|no> if record exists, update it"
        :put "     debug=<yes|no> adds debug output. Default: no"
        :put "     dry=<yes|no> does NOT modify DNS. Default: no"
        :put "     ipv6=<6plane|none> calculates 6PLANE address"
        :put "     zt6plane=<from-zt-central> calculates 6PLANE address. Default:\r\n\t\tfca00:0000:00__:____:____:0000:0000:0001"
        :return [:nothing]
    }
    # handle options
    :if ([:typeof $token]!="str") do={:error "token= must be specific with a ZeroTier API token"}
    :local ztnet $token 
    :if ([:typeof $network]="str") do={
        :set ztnet $network
    } else={:set ztnet [/zerotier/interface/get ([/zerotier/interface/find running]->0) network]} 
    :local dnssuffix $suffix

    # handle 6PLANE

    :local ex6plane "fc00:0000:00__:____:____:0000:0000:0001"
    :if ([:typeof $zt6plane]="str") do={:set ex6plane $zt6plane}
    :local use6plane false
    :if ($ipv6="6plane") do={ 
        :set use6plane true
        :put "\t # 6PLANE AAAA DNS enabled using template: $ex6plane" 
    }
    :local mk6plane do={
        #:set template [:tostr $template]
        #:set ztid [:tostr $ztid]
        :local ztid $memberid
        :put "\t\t# in \$mkplane template=$template ($[:typeof $template]) ztid=$ztid ($[:typeof $ztid])"
        
        :return "$[:pick $template 0 12]$[:pick $ztid 0 2]:$[:pick $ztid 2 6]:$[:pick $ztid 6 10]:$[:pick $template 25 39 ]"
    }

    # get data from ZT Central API via REST
    :local ztmembers [:deserialize from=json ([/tool/fetch url="https://api.zerotier.com/api/v1/network/$ztnet/member" http-header-field="Authorization: token $token" as-value output=user]->"data")]
    :if ($debug~"[yY]" ) do={
            :put "### JSON FROM ZEROTIER ###"
            :put [:serialize to=json $ztmembers]
    }

    # process members for DNS
    :foreach k,v in=$ztmembers do={
        :if ($debug~"[yY]" ) do={
            :put "\r\n### PROCESSING ZT MEMBER \"$($v->"name")\" ###"
            :foreach kc,vc in=($v->"config") do={:put "   $($v->"name") -- $kc = $[:tostr $vc] ($[:typeof $vc])"}
        }
        :foreach ip in=($v->"config"->"ipAssignments") do={
            :if ([:len [/ip/dns/static/find type!=AAAA name="$($v->"name")$dnssuffix"]]=0) do={
                :if ($dry~"[Yy]" = false) do={
                    /ip/dns/static/add type=A address=$ip name="$($v->"name")$dnssuffix"
                } else={ :put "\t\t### DRY MODE - NOT RUN ###" }
                :put "/ip/dns/static add address=$ip name=$($v->"name")$dnssuffix"
            } else={
                :if ($replace~"[Yy]") do={
                    :if ($dry~"[Yy]" = false) do={
                        /ip/dns/static/set [find type!=AAAA name="$($v->"name")$dnssuffix]"] address=$ip 
                    } else={ :put "\t\t### DRY MODE - NOT RUN ###" }
                    :put "/ip/dns/static set $[/ip/dns/static/find type!="AAAA" name="$($v->"name")$dnssuffix"] address=$ip"
                } else={
                    :put "# skip: $ip with name $($v->"name")$dnssuffix"
                }
            }
        } 
        :if ($use6plane) do={
            :local aaaa [$mk6plane template=$ex6plane memberid=($v->"config"->"address")]
            :put "\t\t# got 6PLANE $aaaa from $($v->"config"->"address")"   
            :if ([:len [/ip/dns/static/find type=AAAA name="$($v->"name")$dnssuffix"]]=0) do={
                :if ($dry~"[Yy]" = false) do={
                    /ip/dns/static/add type=AAAA address=$aaaa name="$($v->"name")$dnssuffix"
                } else={ :put "\t\t### DRY MODE - NOT RUN ###" }
                :put "/ip/dns/static add address=$aaaa name=$($v->"name")$dnssuffix"
            } else={
                 :if ($replace~"[Yy]") do={
                    :if ($dry~"[Yy]" = false) do={
                        /ip/dns/static/set [find type=AAAA name="$($v->"name")$dnssuffix]"] address=$aaaa 
                    } else={ :put "\t\t### DRY MODE - NOT RUN ###" }
                    :put "/ip/dns/static set $[/ip/dns/static/find type=AAAA name="$($v->"name")$dnssuffix"] address=$aaaa"
                } else={
                    :put "# skip: 6PLANE for $($v->"name")$dnssuffix using $aaaa"
                }
            } 
        }

    }
}
