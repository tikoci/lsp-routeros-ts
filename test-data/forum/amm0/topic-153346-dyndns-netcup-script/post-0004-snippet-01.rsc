# Source: https://forum.mikrotik.com/t/dyndns-netcup-script/153346/4
# Topic: Dyndns Netcup script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system script
add name=Netcup policy=read,write,test source=":global apikey \"KEY\"\r\
    \n:global apipassword \"PASSWORD\"\r\
    \n:global customerid \"CUSTOMERNR\"\r\
    \n:global theinterface \"WAN1\"\r\
    \n:global ddnshost \"subdomain.domain.de\"\r\
    \n:global ipddns [:resolve \$ddnshost];\r\
    \n:global ipfresh [ /ip address get [/ip address find interface=\$theinterface ] address ]\r\
    \n:if ([ :typeof \$ipfresh ] = nil ) do={\r\
    \n:log info (\"NetcupDDNS: No IP address on \$theinterface .\")\r\
    \n} else={\r\
    \n:for i from=( [:len \$ipfresh] - 1) to=0 do={\r\
    \n:if ( [:pick \$ipfresh \$i] = \"/\") do={\r\
    \n:set ipfresh [:pick \$ipfresh 0 \$i];\r\
    \n}\r\
    \n}\r\
    \n:if (\$ipddns != \$ipfresh) do={\r\
    \n:log info (\"NetcupDDNS: IP-Netcup = \$ipddns\")\r\
    \n:log info (\"NetcupDDNS: IP-Fresh = \$ipfresh\")\r\
    \n:log info \"NetcupDDNS: Update IP needed, Sending UPDATE...!\"\r\
    \n:global jsonRequestBody \"{json request body with new IP and other necessary info}\"\r\
    \n/tool fetch url=\"https://ccp.netcup.net/run/webservice/servers/endpoint.php\?JSON\" http-method=post http-data=\$jsonRequestBody mode=https dst-p\
    ath=(\"/Netcup.\".\$ddnshost)\r\
    \n:delay 1\r\
    \n:global str [/file find name=\"Netcup.\$ddnshost\"];\r\
    \n/file remove \$str\r\
    \n:global ipddns \$ipfresh\r\
    \n:log info \"NetcupDDNS: IP updated to \$ipfresh!\"\r\
    \n} else={\r\
    \n:log info \"NetcupDDNS: dont need changes\";\r\
    \n} }"
