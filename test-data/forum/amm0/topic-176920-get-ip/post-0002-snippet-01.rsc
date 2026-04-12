# Source: https://forum.mikrotik.com/t/get-ip/176920/2
# Topic: get IP
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local dbip ([/tool fetch url="https://api.db-ip.com/v2/free/self/ipAddress" as-value output=user]->"data")
:put $dbip
}
