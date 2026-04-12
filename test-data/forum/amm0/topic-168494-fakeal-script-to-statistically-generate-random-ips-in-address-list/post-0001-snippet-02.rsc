# Source: https://forum.mikrotik.com/t/fakeal-script-to-statistically-generate-random-ips-in-address-list/168494/1
# Topic: $FAKEAL - script to statistically generate random IPs in address-list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

$FAKEAL help
Usage:
$FAKEAL [spread=0..119304647] [density=1..100] [list=list_name] [replace={no|false|off|0}] [start=ip.ad.dr.ess]
    spread=  num of /24's to distribute random entires over (e.g. how many / 254), default is 1 (/24)
    density= percentage (as int) of used address over the total range (i.e. 50 = 50% of possible IP), default is 25
    list=    default is FAKEAL but can be any valid name for /ip firewall address-list
    start=   the first possible IP address to use, default is 169.254.0.0
    replace= any previous list created by $FAKEAL is removed, use 'replace=no' to keep an old entires in list, default is yes
