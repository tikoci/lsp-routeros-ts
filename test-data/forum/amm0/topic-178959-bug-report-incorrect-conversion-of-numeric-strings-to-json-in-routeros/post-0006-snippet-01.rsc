# Source: https://forum.mikrotik.com/t/bug-report-incorrect-conversion-of-numeric-strings-to-json-in-routeros/178959/6
# Topic: Bug Report: Incorrect Conversion of Numeric Strings to JSON in RouterOS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global zero6str "0000000"    
:put "$zero6str $[:typeof $zero6str]"
# 0000000 str
:put [:serialize to=json $zero6str]
# 0.000000
