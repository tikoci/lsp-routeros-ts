# Source: https://forum.mikrotik.com/t/example-creating-self-signed-certificates-including-apple-mobileconfig-using-tikbook/267709/1
# Topic: ✍️ Example: Creating self-signed certificates, including Apple `.mobileconfig`, using TikBook
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip dns static remove [find comment=reverse-proxy-sni]

/ip dns static add address="$[/app/settings get router-ip]$[/app/settings get assumed-router-ip]" match-subdomain=yes name=$domainname type=A comment="reverse-proxy-sni"

/ip dns static export terse where comment=reverse-proxy-sni
