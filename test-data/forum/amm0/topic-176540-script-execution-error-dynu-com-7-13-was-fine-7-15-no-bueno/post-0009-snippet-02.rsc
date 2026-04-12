# Source: https://forum.mikrotik.com/t/script-execution-error-dynu-com-7-13-was-fine-7-15-no-bueno/176540/9
# Topic: Script Execution Error - Dynu.com 7.13 was fine 7.15 no bueno
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global updateDynu 
:set updateDynu do={
    # handle parameters to Dynu "cmd function"
    :local ddnshost $1
    :local theinterface $interface
    :local ddnsuser $user
    :local ddnspass $password
    :local dynuGetUpdateUrl "https://api.dynu.com/nic/update?hostname=$ddnshost"
    
    # helper functions to print help and log...
    :local printUsage do={
        :put " Usage"
        :put "\$updateDynu <ddns_hostname> user=<dynu_user> password=<dynupass> interface=<WAN> [force=yes]"
    }
    
    # check that DDNS name is provided as 1st argument, error if not
    :if ([:typeof $1]!="str") do={
        $printUsage
        :local errmsg "ERROR: \$updateDynu requires a DDNS hostname [$ddnshost]"
        /log error $errmsg 
        :error $errmsg 
    }

    # check that DDNS name is provided as 1st argument, error if not
    :if (([:typeof $user]!="str") || ([:typeof $password]!="str")) do={
        $printUsage
        :local errmsg "ERROR: \$updateDynu requires a username and password [$ddnshost]"
        /log error $errmsg 
        :error $errmsg 
    }

    # if "interface=ether1" is provided use that, do not detect 
    # get the WAN ip address (removing /xx prefix)
    :local wanip 
    :if ([:typeof $theinterface]="str") do={
        /log/debug [:put "$ddnshost update using WAN interface: $theinterface "]
        :local wanipid [/ip/address/find interface=($theinterface)]
        :if ([:len $wanipid]!=1) do={
           :local errmsg "ERROR: \$updateDynu invalid interface $theinterface, found $[:tostr $wanipid]"
            /log error $errmsg 
            :error $errmsg  
        }
        :local wanipprefix [/ip/address/get $wanipid address]
        :set wanip [:tostr [:pick $wanipprefix 0 [:find $wanipprefix "/" ]]]
        /log/debug [:put "$theinterface got ipprefix=$wanipprefix ip=$wanip updating $ddnshost"]
        :if ([:typeof [:toip $wanip]]!="ip") do={
            :local errmsg "ERROR: \$updateDynu invalid /ip/address. prefix=$[:tostr $wanipprefix] ip=$[:tostr $wanip]"
            /log error $errmsg 
            :error $errmsg 
        }
        :set dynuGetUpdateUrl "$dynuGetUpdateUrl&myip=$wanip" 
    } else={
        /log/info [:put "$ddnshost no interface= provided, auto-detected based on http request be used"]
    }

    # is update needed?
    :local doUpdate false
    :local cacheDns [:tostr [:resolve $ddnshost]]
    :local resolvedDns [:tostr [:resolve $ddnshost  server=[:resolve NS1.DYNU.COM]]]
    :if ($resolvedDns!=$wanip) do={
        /log/debug [:put "will attempt update, $resolvedDns does not equal $[:tostr $wanip]"]
        :set doUpdate true
    }
    :if ($force~"(yes|true|y|1)") do={
        /log/debug [:put "will attempt update, force=yes for $resolvedDns"]
        :set doUpdate true
    }
    #/log/debug [:put "DDNS update: $doUpdate <= resolve=$resolvedDns cache=$cacheDns force=$force ip=$wanip host=$ddnshost"]
    
    # update dynu
    :if ($doUpdate) do={
        :onerror err in={
            /log/debug [:put "DDNS HTTP update started, using $dynuGetUpdateUrl"]
            :local dynuHttp [/tool/fetch http-method=get user=$ddnsuser password=$ddnspass url=$dynuGetUpdateUrl as-value output=user]
            /log/debug [:put "DDNS HTTP update finished, got: $[:tostr $dynuHttp]"]
            :if (($dynuHttp->"data")~"good") do={
                /log info [:put "DDNS $ddnshost updated from $resolvedDns to $[:pick ($dynuHttp->"data") 5 32]"]
            } else={
                :if (($dynuHttp->"data")~"badauth") do={
                    :error "** failed due to auth issue, $($dynuHttp->"data")" 
                } 
                /log warning [:put "WARNING: $ddnshost update reported not $($dynuHttp->"data")"]
            }
        } do={
            :local errmsg "ERROR: $ddnshost from $resolvedDns had HTTP issue: $err"
            /log error [:put $errmsg]
            :return [:nothing] 
        }
    } else={
        /log/info [:put "no update of $ddnshost needed <= resolve=$resolvedDns cache=$cacheDns ip=$wanip"]
    }
    :return [:nothing]
}
