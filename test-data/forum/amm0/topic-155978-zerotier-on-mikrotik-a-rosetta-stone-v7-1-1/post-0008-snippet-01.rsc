# Source: https://forum.mikrotik.com/t/zerotier-on-mikrotik-a-rosetta-stone-v7-1-1/155978/8
# Topic: ZeroTier on Mikrotik – a rosetta stone [v7.1.1+]
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global ZTPEERS
:set ZTPEERS do={
    # params
    :local warnlatency 100ms
    :local warnpeerdelay 10s
    :local pingspeedlen 5s
    :local pingspeedint 250ms

    # find "active" peers from /zeroteir/peer
    :local activePeerIds [/zerotier/peer/find path~"active"]

    # get data for each peer into an array
    :local activePeers [:toarray ""]
    :for i from=0 to=([:len $activePeerIds]-1) do={
        :set ($activePeers->$i) [/zerotier/peer get ($activePeerIds->$i)]
    } 

    # loop though each peer to do some checks
    :foreach ztpeer in=$activePeers do={
        # parse the "path" to find ip/port
        :local addrport ($ztpeer->"path"->2)
        :local addr [:pick $addrport 0 [:find $addrport "/"]]
        :local port [:pick $addrport ([:find $addrport "/"]+1) [:len $addrport] ]
        :set ($ztpeer->"ipaddr") "$addr:$port"

        # humanize latency "time"
        :local platency [:tostr ($ztpeer->"latency")]
        :local platency ("" . [:pick $platency 6 8] . "s " . [:pick $platency 9 13] . "ms") 

        # output headers 
        #   note: colorize output is from /terminal/styles...
        /terminal/style syntax-old
        :put "$($ztpeer->"role")\t$platency\t$addrport" 
        # warn on high latency by colorizing it
        :if (($ztpeer->"latency") > $warnlatency) do={
            # reprint latency in RED
            /terminal/cuu
            /terminal/style error
            :put "\t$platency"
        }
            
        # run a ping-speed 
        /terminal/style "syntax-noterm" 
        :put "\t PING-SPEED test   $addr $([:pick $pingspeedlen 6 8])s@$([:pick $pingspeedint 9 13])ms"
        :local pingresults [/tool/ping-speed address=$addr duration=$pingspeedlen interval=$pingspeedint as-value]
        :local avgpingkb (($pingresults->"average")/1024) 
        /terminal/cuu
        :if (avgpingkb < 1000) do={            
            /terminal/style error
            :put "\t\t\t got <1Mb/s, average: $avgpingkb Kb/s      "
        } else={
            /terminal/style "syntax-noterm" 
            :put "\t\t\t average: $avgpingkb Kb/s                                "
        }

        # output last tx/rx time from peer
        # TODO: colorize long times in last peer packet times 
        :local rxtime [:totime [:pick ($ztpeer->"path"->3) 6 32 ]]
        :local txtime [:totime [:pick ($ztpeer->"path"->4) 5 32 ]]
        {
            /terminal/style ambiguous
            :put "\t\t$($ztpeer->"path"->3)"
            /terminal/cuu
            :put "\t\t\t\t\t$($ztpeer->"path"->4)"
        }
        :if ($rxtime>$warnpeerdelay) do={
            { /terminal/cuu; /terminal/style error; :put "\t\t$($ztpeer->"path"->3)" }
        }
        :if ($txtime>$warnpeerdelay) do={
            { /terminal/cuu; /terminal/style error; :put "\t\t\t\t\t$($ztpeer->"path"->4)" }
        }
        /terminal/style none


        # output connections associated with ZT
        :local ztconns [/ip/firewall/connection/find dst-address=$addrport]
        :if ([:len ztconns] > 0) do={
            :set ($ztpeer-"conntrack") [/ip/firewall/connection/print as-value where dst-address=$addrport]
        } else={
            {/terminal/style error; :put "\tno associated connections found in firewall"}
        }
        /ip/firewall/connection/print where dst-address=($ztpeer->"ipaddr")
        :put ""
    }
}

[code]
