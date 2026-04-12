# Source: https://forum.mikrotik.com/t/inconsistence-between-config-export-from-rest-api-vs-webui/262819/4
# Topic: Inconsistence between config export from REST API vs WebUI
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/tool/fetch http-method=post  url="http://127.0.0.1/rest/ip/dns/export" password=[/terminal/ask prompt="password"] user=[/terminal/ask prompt="username"]  http-header-field="content-type:application/json"  http-data=[:serialize to=json {"file"="dnsexport.rsc";"terse"=true}] output=user
