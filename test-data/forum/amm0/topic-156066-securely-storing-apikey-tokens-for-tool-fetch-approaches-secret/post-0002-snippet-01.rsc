# Source: https://forum.mikrotik.com/t/securely-storing-apikey-tokens-for-tool-fetch-approaches-secret/156066/2
# Topic: Securely storing apikey/tokens for /tool/fetch... Approaches?  == $SECRET
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

> $SECRET set MTforumpw password=ItIsASecretDontYouKnow

 > :put [$SECRET get MTforumpw]
ItIsASecretDontYouKnow
 
 > $SECRET print
Columns: NAME, SERVICE, PASSWORD, PROFILE
# NAME       SERVICE  PASSWORD                          PROFILE
;;; used by $SECRET
1 MTforumpw  async    ItIsASecretDontYouKnow            null
