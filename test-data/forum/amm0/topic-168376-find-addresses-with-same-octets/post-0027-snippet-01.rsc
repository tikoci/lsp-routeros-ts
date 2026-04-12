# Source: https://forum.mikrotik.com/t/find-addresses-with-same-octets/168376/27
# Topic: find addresses with same octets
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

$fantasylist help

Usage:
$fantasylist [spread=4] [density=50] [list=$fantasylist] [replace=yes] [ip=169.254.0.0] [fidelity=10]
        spread=         num of /24's to distribute random entires over (e.g. how many / 254)
        density=        percentage (as int) of used address over the total range (i.e. 50 = 50% of possible IP)
        list=           default is $fantasylist but can be any /ip/firewall/address-list
        ip=             the first possible IP address to use (e.g. 169.254.0.0 )
        fidelity=       during IP randomization, dups can happen...
                but on-error is slow, so use lower fidelity=1 to speed creation
                (at expense of accuracy to number of IPs requested by density=)
        replace=        any previous list created by $fantasylist is removed,
                use 'replace=no' to keep an old entires in list
