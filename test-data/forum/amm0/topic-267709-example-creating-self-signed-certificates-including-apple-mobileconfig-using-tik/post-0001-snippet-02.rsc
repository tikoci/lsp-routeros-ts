# Source: https://forum.mikrotik.com/t/example-creating-self-signed-certificates-including-apple-mobileconfig-using-tikbook/267709/1
# Topic: ✍️ Example: Creating self-signed certificates, including Apple `.mobileconfig`, using TikBook
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global certkeysize 2048

:global digestalgo "sha256"

:global certdays 365

:global certcadays 1825

:global scepdays 10

:global domainname $scepbase

:global certserversans ("DNS:$domainname","DNS:*.$domainname")

:put "$certserversans"
