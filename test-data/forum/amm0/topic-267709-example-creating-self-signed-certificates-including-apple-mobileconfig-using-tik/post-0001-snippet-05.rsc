# Source: https://forum.mikrotik.com/t/example-creating-self-signed-certificates-including-apple-mobileconfig-using-tikbook/267709/1
# Topic: ✍️ Example: Creating self-signed certificates, including Apple `.mobileconfig`, using TikBook
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/certificate add name="$scepbase-$sysname-ca" organization=$scepbase common-name="$[:convert transform=uc $scepbase] Authority ($sysname)" unit=$sysname digest-algorithm=$digestalgo days-valid=$certcadays key-usage=key-cert-sign,crl-sign key-size=$certkeysize
