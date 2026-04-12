# Source: https://forum.mikrotik.com/t/frequent-empty-variables-in-scripts-turned-out-to-be-bug/168049/8
# Topic: Frequent empty variables in scripts turned out to be Bug ?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local func do={ :return "txt $domainName" }

:put [$func domainName=123]
:put [$func domainName=223]
:put [$func domainName=323]
:put [$func domainName=423]
}
