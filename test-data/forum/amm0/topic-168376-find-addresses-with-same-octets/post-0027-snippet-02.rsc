# Source: https://forum.mikrotik.com/t/find-addresses-with-same-octets/168376/27
# Topic: find addresses with same octets
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# create 25 IPs (density=10 is 10%) in an address-list over 169.254.0.0/24 (spread=1 is 254 IPs)
$fantasylist spread=1 density=10
     remove  previous list: $fantasylist
     adding  169.254.0.100   in $fantasylist (25 / 25)
     done! requested 25 and added 25 random IPs (off by 0) to $fantasylist (len=25) after 00:00:02.517758220

# create 645 IPs (density=1 is 1%) in an address-list over 169.254.0.0/16 (so spread=254 is /16)
$fantasylist spread=254 density=1
    remove  previous list: $fantasylist
    adding  169.254.134.194 in $fantasylist (645 / 645)
    done! requested 645 and added 645 random IPs (off by 0) to $fantasylist (len=645) after 00:00:03.615506500
