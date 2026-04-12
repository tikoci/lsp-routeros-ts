# Source: https://forum.mikrotik.com/t/securely-storing-apikey-tokens-for-tool-fetch-approaches-secret/156066/6
# Topic: Securely storing apikey/tokens for /tool/fetch... Approaches?  == $SECRET
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
# ...
:local headers "Authorization: bearer $[$SECRET get mtforumpw]"        
:local resp [/tool/fetch url="$url" http-method="$method" http-header-field="$headers" http-data=($payload) output="user" as-value]
:put $resp
# ...
}
