# Source: https://forum.mikrotik.com/t/adjusting-netwatch-icmp-check-by-of-current-rtt-values-scalenetwatch/174380/1
# Topic: Adjusting netwatch ICMP check by % of current RTT values... `$scalenetwatch`
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# create a new ICMP netwatch if needed

/tool/netwatch add type=icmp host=1.1.1.1 comment=scaletest interval=3s

# then use "find" to locate one to update (here it's find'ing the one above)
# to call the \$scalenetwatch function, which will set the RTT and jitter to +25% from last test

$scalenetwatch [/tool/netwatch find comment=scaletest]
