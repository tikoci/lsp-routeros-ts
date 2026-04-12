# Source: https://forum.mikrotik.com/t/adjusting-netwatch-icmp-check-by-of-current-rtt-values-scalenetwatch/174380/1
# Topic: Adjusting netwatch ICMP check by % of current RTT values... `$scalenetwatch`
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

$scalenetwatch denom=2 [/tool/netwatch find comment=scaletest]    
using adjustment of 50%
changed 1.1.1.1 rtt-avg = 00:00:00.013786500     [ diff: 2ms old: 00.011461 ]
changed 1.1.1.1 rtt-jitter = 00:00:00.000957     [ diff: 0ms old: 00.000897 ]
changed 1.1.1.1 rtt-max = 00:00:00.014274        [ diff: 2ms old: 00.012040 ]
changed 1.1.1.1 rtt-stdev = 00:00:00.000315      [ diff: 0ms old: 00.000312 ]
update 1.1.1.1 done
