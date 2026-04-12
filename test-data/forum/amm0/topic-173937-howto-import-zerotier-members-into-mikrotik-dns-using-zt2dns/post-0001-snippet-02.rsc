# Source: https://forum.mikrotik.com/t/howto-import-zerotier-members-into-mikrotik-dns-using-zt2dns/173937/1
# Topic: HOWTO:  Import ZeroTier Members into Mikrotik DNS using $ZT2DNS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

ZT_TOKEN=zerotier-API-token-FROM-my.zerotier.com-AccountPage
ZT_NET=zt-network-id
curl -X GET -H "Authorization: token $ZT_TOKEN" https://api.zerotier.com/api/v1/network/$ZT_NET/member |
jq -r '(.[] | [.config.ipAssignments[], .name]) | @tsv' |
awk 'length($1)>0 && length($2)>0 { print "/ip/dns/static add address="$1" name="$2".zt" } '
