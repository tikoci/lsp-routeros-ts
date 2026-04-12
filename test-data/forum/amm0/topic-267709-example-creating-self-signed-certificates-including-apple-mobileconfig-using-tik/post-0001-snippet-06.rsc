# Source: https://forum.mikrotik.com/t/example-creating-self-signed-certificates-including-apple-mobileconfig-using-tikbook/267709/1
# Topic: ✍️ Example: Creating self-signed certificates, including Apple `.mobileconfig`, using TikBook
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/certificate add name="$scepbase-$sysname-router" organization=$scepbase common-name=$domainname subject-alt-name=$certserversans unit=$sysname digest-algorithm=$digestalgo days-valid=$certdays key-usage=digital-signature,content-commitment,key-encipherment,data-encipherment,key-agreement,tls-server,tls-client,code-sign,email-protect,timestamp,ocsp-sign key-size=$certkeysize
