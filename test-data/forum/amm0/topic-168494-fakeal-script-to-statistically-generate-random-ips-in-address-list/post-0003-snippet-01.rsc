# Source: https://forum.mikrotik.com/t/fakeal-script-to-statistically-generate-random-ips-in-address-list/168494/3
# Topic: $FAKEAL - script to statistically generate random IPs in address-list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global ippa do={
    /ip/firewall/address-list remove [find list=test_End]
    /ip/firewall/address-list remove [find list~"^test_[^S]"]
    :put "before @rextended aggregation there are $[:len [/ip/firewall/address-list/find list=test_Start]] IPs"    
    :local tstart [:timestamp]
    /ip firewall address-list {
        :local toipprefix do={:return [[:parse ":return $1"]]}
        :local IPmustMask "^((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\/(3[0-2]|[0-2]\?[0-9])\$"
        :local IPoptiMask "^((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])(\\/(3[0-2]|[0-2]\?[0-9])){0,1}\$"
        :local IPwoutMask "^((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\$"

        :local field 0.0.0.0/0
        :local sub   0.0.0.0/0
        :local sub1  0.0.0.0/0
        :local sub2  0.0.0.0/0
        :local temp  0.0.0.0

    # from 32 to 31
        :local addrarray [:toarray ""]
        :local newarray  [:toarray ""]
        :foreach item in=[print as-value where address~$IPoptiMask and list="test_Start"] do={
            :set addrarray ($addrarray , ($item->"address"))
        }
        :foreach item in=$addrarray do={
            :set field $item
            :if ($field~$IPwoutMask) do={:set field [:toip $field]} ; :if ($field~$IPmustMask) do={:set field [$toipprefix $field]}
            :if ([:typeof $field] = "ip-prefix") do={
                :if ($field~"/31\$") do={
                    :if ([:find $newarray $field] = [:nothing]) do={
                        :set newarray ($newarray , $field)
                    }
                }
            }
            :if ([:typeof $field] = "ip") do={
                :set temp $field
                :set sub  [$toipprefix ("$($temp & 255.255.255.254)/31")]
                :set sub1 ($temp & 255.255.255.254)
                :set sub2 (($temp & 255.255.255.254) + 1)
                :if (([:find $newarray $sub] = [:nothing]) and ([:find $newarray $field] = [:nothing])) do={
                    :if (([:find $addrarray $sub1] = [:nothing]) or ([:find $addrarray $sub2] = [:nothing])) do={
                        :set newarray ($newarray , $field)
                    } else={
                        :set newarray ($newarray , $sub)
                    }
                }
            }
        }

    # useless, just for debug
    #    :foreach item in=$newarray do={
    #        add list="test_Inter31" address=$item
    #    }

    # from 31 to 30
        :local addrarray $newarray
        :local newarray  [:toarray ""]
        :foreach item in=$addrarray do={
            :set field $item
            :if ($field~$IPwoutMask) do={:set field [:toip $field]} ; :if ($field~$IPmustMask) do={:set field [$toipprefix $field]}
            :if ([:typeof $field] = "ip") do={
                :if ([:find $newarray $field] = [:nothing]) do={
                    :set newarray ($newarray , $field)
                }
            }
            :if ([:typeof $field] = "ip-prefix") do={
                :if ($field~"/30\$") do={
                    :if ([:find $newarray $field] = [:nothing]) do={
                        :set newarray ($newarray , $field)
                    }
                }
                :if ($field~"/31\$") do={
                    :set temp [:toip [:pick $field 0 [:find $field "/" -1]]]
                    :set sub  [$toipprefix ("$($temp & 255.255.255.252)/30")]
                    :set sub1 [$toipprefix ("$($temp & 255.255.255.252)/31")]
                    :set sub2 [$toipprefix ("$(($temp & 255.255.255.252) + 2)/31")]
                    :if (([:find $newarray $sub] = [:nothing]) and ([:find $newarray $field] = [:nothing])) do={
                        :if (([:find $addrarray $sub1] = [:nothing]) or ([:find $addrarray $sub2] = [:nothing])) do={
                            :set newarray ($newarray , $field)
                        } else={
                            :set newarray ($newarray , $sub)
                        }
                    }
                }
            }
        }

    # useless, just for debug
    #    :foreach item in=$newarray do={
    #        add list="test_Inter30" address=$item
    #    }

    # from 30 to 29
        :local addrarray $newarray
        :local newarray  [:toarray ""]
        :foreach item in=$addrarray do={
            :set field $item
            :if ($field~$IPwoutMask) do={:set field [:toip $field]} ; :if ($field~$IPmustMask) do={:set field [$toipprefix $field]}
            :if ([:typeof $field] = "ip") do={
                :if ([:find $newarray $field] = [:nothing]) do={
                    :set newarray ($newarray , $field)
                }
            }
            :if ([:typeof $field] = "ip-prefix") do={
                :if ($field~"/(29|31)\$") do={
                    :if ([:find $newarray $field] = [:nothing]) do={
                        :set newarray ($newarray , $field)
                    }
                }
                :if ($field~"/30\$") do={
                    :set temp [:toip [:pick $field 0 [:find $field "/" -1]]]
                    :set sub  [$toipprefix ("$($temp & 255.255.255.248)/29")]
                    :set sub1 [$toipprefix ("$($temp & 255.255.255.248)/30")]
                    :set sub2 [$toipprefix ("$(($temp & 255.255.255.248) + 4)/30")]
                    :if (([:find $newarray $sub] = [:nothing]) and ([:find $newarray $field] = [:nothing])) do={
                        :if (([:find $addrarray $sub1] = [:nothing]) or ([:find $addrarray $sub2] = [:nothing])) do={
                            :set newarray ($newarray , $field)
                        } else={
                            :set newarray ($newarray , $sub)
                        }
                    }
                }
            }
        }

        :foreach item in=$newarray do={
            add list="test_End" address=$item
        }
    }
    :put "completed in $([:timestamp]-$tstart)"
    :put "after @rextended aggregation there are $[:len [/ip/firewall/address-list/find list=test_End]] IP"    
}
