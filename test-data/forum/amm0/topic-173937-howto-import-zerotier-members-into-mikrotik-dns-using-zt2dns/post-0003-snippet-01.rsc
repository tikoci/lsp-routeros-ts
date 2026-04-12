# Source: https://forum.mikrotik.com/t/howto-import-zerotier-members-into-mikrotik-dns-using-zt2dns/173937/3
# Topic: HOWTO:  Import ZeroTier Members into Mikrotik DNS using $ZT2DNS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

### DRY MODE - NOT RUN ###
/ip/dns/static add address=172.23.13.229 name=me.zttest
# in $mkplane template=fcae:42c9:c1__:____:____:0000:0000:0001 (str) ztid=1fceb9a1b0 (str)
# got 6PLANE fcae:42c9:c11f:ceb9:a1b0:0000:0000:0001 from 1fceb9a1b0
### DRY MODE - NOT RUN ###
/ip/dns/static add address=fcae:42c9:c11f:ceb9:a1b0:0000:0000:0001 name=me.zttest
