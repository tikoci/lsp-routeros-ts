# Source: https://forum.mikrotik.com/t/tikbook-notebook-and-tools-for-visual-studio-code-including-routeros-lsp/263305/1
# Topic: 📓 TikBook™ — notebook and tools for Visual Studio Code, including RouterOS LSP
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/user/group add name=tikbook-read policy=read,api,rest-api
/user add name=tikbook group=tikbook-read password=[/terminal/ask prompt="Select password for new 'tikbook' account:"]
