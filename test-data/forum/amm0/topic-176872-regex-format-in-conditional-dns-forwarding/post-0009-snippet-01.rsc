# Source: https://forum.mikrotik.com/t/regex-format-in-conditional-dns-forwarding/176872/9
# Topic: Regex Format in Conditional DNS forwarding
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put ("aaa"~"[a]{3}")      
# true
:put ("aaa"~"[a]{4}") 
# false
