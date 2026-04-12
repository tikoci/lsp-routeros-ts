# Source: https://forum.mikrotik.com/t/adjusting-netwatch-icmp-check-by-of-current-rtt-values-scalenetwatch/174380/1
# Topic: Adjusting netwatch ICMP check by % of current RTT values... `$scalenetwatch`
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global scalenetwatch do={
    :local scaletime do={:return [:totime "$([:tonsec [:totime $1]] + ([:tonsec [:totime $1]]/$2))ns"]}
    :local setchg do={
        :local attrs [/tool/netwatch/get $1]
        :local attname "thr-$[:pick $2 4 12]"
        :local prev ($attrs->$attname)
        :local diffms (([:tonsec [:totime $3]] - [:tonsec [:totime $prev]])/1000000)
        [[:parse "/tool/netwatch set $1 $attname=$3"]]
        :put "changed $($attrs->"host")\t$2 = $3 \t [ diff: $($diffms)ms old: $[:pick $prev 6 99] ]"
    }
    :local nwattrs 
    :do { :set nwattrs [/tool/netwatch get $1] } on-error={
        :error "\$$0 requires an .id of netwatch – use [/tool/netwatch find host=1.1.1.1 type=icmp] or similar as arg"
    }
    # default 1/4 or 25% 
    :local ldenom 4
    :if ([:typeof [:tonum $denom]]~"num") do={
        :set ldenom [:tonum $denom]
    } else={
        :put "using default denom=4 or +25% of current value to set netwatch thresholds for ICMP RTT"
        :put "\thint:  use \$$0 denom=4 [/tool/netwatch find host=1.1.1.1] "
        :put "\t       denom=<num> is the adjustment expressed as: 1 / <num>"
        :put "\t       so denom=2 means 1/2 or 50% - default: denom=2 or 25%"
    }
    :if ($ldenom > 0) do={
        :put "using adjustment of $(100 / $ldenom)%"
    } else={
        :local perc
        # handle denom=0, which causes divide by zero error
        :do { :set perc (100 / $ldenom) } on-error={ :set perc 0}
        :put "warn: negative adjustment of $perc% - you may get failed tests"
    }
    :foreach k,v in=$nwattrs do={
        :if ($k~"rtt-avg|rtt-jitter|rtt-max|rtt-stdev") do={
            :if ($ldenom = 0) do={ $setchg $1 $k $v } else={ $setchg $1 $k [$scaletime $v $ldenom] } 
        }   
    }
    :put "update $($nwattrs->"host") done"
    :return [/tool/netwatch get $1]
}
