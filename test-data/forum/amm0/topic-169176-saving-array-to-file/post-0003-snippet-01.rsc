# Source: https://forum.mikrotik.com/t/saving-array-to-file/169176/3
# Topic: Saving array to file
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global before {field1="mystr";field2=2} 
/file add name=diskarray contents=$before
:global after [:toarray [/file get diskarray contents]]
