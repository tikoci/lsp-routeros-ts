# Source: https://forum.mikrotik.com/t/howto-import-zerotier-members-into-mikrotik-dns-using-zt2dns/173937/1
# Topic: HOWTO:  Import ZeroTier Members into Mikrotik DNS using $ZT2DNS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global ZT2DNS do={
    :if ($1="help") do={
        :put "\$ZT2DNS - updates static DNS on Mikrotik from a ZeroTier network"
        :put "  usage: \$ZT2DNS token=<api_token> [network=<network_id>] [suffix=<dns_domain>]"
        :put "     <api_token> is 'API Access Tokens' from https://my.zerotier.com/account "
        :put "     <network_id> is ZeroTier network ID to use. Default: first running ZT interface"
        :put "     <suffix> added to name= in DNS entries, must include any leading dot. Default: \"\""
        :return [:nothing]
    }
    :if ([:typeof $token]!="str") do={:error "token= must be specific with a ZeroTier API token"}
    :local ztnet $token 
    :if ([:typeof $network]="str") do={
        :set ztnet $network
    } else={:set ztnet [/zerotier/interface/get ([/zerotier/interface/find running]->0) network]} 
    :local dnssuffix $suffix
    :local ztmembers [:deserialize from=json ([/tool/fetch url="https://api.zerotier.com/api/v1/network/$ztnet/member" http-header-field="Authorization: token $token" as-value output=user]->"data")]
    :foreach k,v in=$ztmembers do={
        :foreach ip in=($v->"config"->"ipAssignments") do={
            :if ([:len [/ip/dns/static/find name="$($v->"name")$dnssuffix"]]=0) do={
                /ip/dns/static/add address=$ip name="$($v->"name")$dnssuffix"
                :put "/ip/dns/static add address=$ip name=$($v->"name")$dnssuffix"
            } else={:put "# skip: $ip with name $($v->"name")$dnssuffix"}
        } 
    }
}
# v1.2
