# Source: https://forum.mikrotik.com/t/example-creating-self-signed-certificates-including-apple-mobileconfig-using-tikbook/267709/1
# Topic: ✍️ Example: Creating self-signed certificates, including Apple `.mobileconfig`, using TikBook
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global keyUsage "signature"

:global retries 8

:global retryDelay 15

:global clientname "client$[:tonum [:timestamp]]"

:global exportfilename "/$scepbase-$sysname-$($clientname).mobileconfig"

:put $exportfilename
