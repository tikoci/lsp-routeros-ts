# Source: https://forum.mikrotik.com/t/regex-format-in-conditional-dns-forwarding/176872/25
# Topic: Regex Format in Conditional DNS forwarding
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put ("a.com"~"a[.]com") 
# true
:put ("a1com"~"a[.]com") 
# false
