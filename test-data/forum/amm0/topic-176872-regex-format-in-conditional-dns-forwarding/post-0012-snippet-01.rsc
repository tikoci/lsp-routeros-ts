# Source: https://forum.mikrotik.com/t/regex-format-in-conditional-dns-forwarding/176872/12
# Topic: Regex Format in Conditional DNS forwarding
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put ("test-01.ad.localdomain"~"^(?![\\w]*[-][\\d]{2})(.*[\\.]?ad\\.localdomain)\$")
# false
 :put ("matchtest"~"[m][a][t][c][h].*")
# true
:put ("matchtest"~"^[t][e][s][t].*") 
# false
