# Source: https://forum.mikrotik.com/t/im-seeking-a-little-help-please-curl-fetch-translation/183538/2
# Topic: Im seeking a little help please. Curl -> fetch translation.
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:local accountid "xxx"
:local listid "xxx"
:local apitoken "xxx"
/tool/fetch http-method=delete url="https://api.cloudflare.com/client/v4/accounts/$accountid/rules/lists/$listid/items" http-header-field=("Content-Type: application/json","Authorization: Bearer $apitoken")
