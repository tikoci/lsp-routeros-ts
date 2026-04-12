# Source: https://forum.mikrotik.com/t/how-to-query-by-query-words/178945/5
# Topic: how to query by query words
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip firewall raw
add action=passthrough chain=chain1 comment=show
add action=passthrough chain=chain2
add action=log chain=chain2 comment=show
add action=log chain=chain1

:global auth {"user"="XXXX"; "password"="XXXXX"}
:global bodyarray {".proplist"="chain,action,comment" ; ".query"={ "chain=chain1"; "chain=chain2"; "#|"; "action=log"; "action=passthrough"; "#|&"; "comment=show"}}     
/tool fetch http-method=post user=($auth->"user") password=($auth->"password") \
     http-header-field="Content-Type: application/json" \
     url=http://localhost/rest/ip/firewall/raw/print \
     http-data=[:serialize to=json $bodyarray] \
     output=user
