# Source: https://forum.mikrotik.com/t/rest-api-problems/156055/5
# Topic: REST API problems
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# you need a Mikrotik user/password to call REST
:global user CHANGE_ME
:global password CHANGE_ME

# "$fetchrest function, it takes a type= in $type to control the Content-Type: used in this test
:global fetchrest do={/tool/fetch url=https://localhost/rest/ip/firewall/layer7-protocol http-header-field="Content-Type: $type" http-method=put http-data="{\"name\": \"rest-put-charset-$[:timestamp]\", \"regexp\": \"test\"}" user=$user password="$password"}

# above rest call adds a layer7-protocol – which are ignored if not used, so safe to add something to them
