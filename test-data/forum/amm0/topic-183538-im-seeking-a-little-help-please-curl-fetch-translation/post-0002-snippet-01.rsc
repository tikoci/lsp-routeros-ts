# Source: https://forum.mikrotik.com/t/im-seeking-a-little-help-please-curl-fetch-translation/183538/2
# Topic: Im seeking a little help please. Curl -> fetch translation.
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

#		*** TIPS: Parsing JSON ***
#  Your request may return a JSON response.
#  RouterOS has support to parse the JSON string data returned into RouterOS array.
#  For example,
#	:global resp [/tool/fetch http-method=delete url="https://api.cloudflare.com/client/v4/accounts/\$accountid/rules/lists/\$listid/items" http-header-field=("Content-Type: application/json","Authorization: Bearer \$apitoken") as-value output=user]
#	:global json [:deserialize ($resp->"data") from=json]
#	:put $json

/tool/fetch http-method=delete url="https://api.cloudflare.com/client/v4/accounts/\$accountid/rules/lists/\$listid/items" http-header-field=("Content-Type: application/json","Authorization: Bearer \$apitoken")
