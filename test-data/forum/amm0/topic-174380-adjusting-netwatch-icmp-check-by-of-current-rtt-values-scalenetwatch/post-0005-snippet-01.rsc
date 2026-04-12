# Source: https://forum.mikrotik.com/t/adjusting-netwatch-icmp-check-by-of-current-rtt-values-scalenetwatch/174380/5
# Topic: Adjusting netwatch ICMP check by % of current RTT values... `$scalenetwatch`
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:foreach k,v in=$nwattrs do={
        :if ($k~"rtt-avg|rtt-jitter|rtt-max|rtt-stdev") do={
            :if ($ldenom = 0) do={ $setchg $1 $k $v } else={ $setchg $1 $k [$scaletime $v $ldenom] } 
        }   
    }
