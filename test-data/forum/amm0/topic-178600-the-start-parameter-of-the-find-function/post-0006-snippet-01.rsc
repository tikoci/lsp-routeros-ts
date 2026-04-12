# Source: https://forum.mikrotik.com/t/the-start-parameter-of-the-find-function/178600/6
# Topic: The start parameter of the :find function
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [:tobool [:grep "return abcaz" pattern="z.c."]] 
# false
:put [:tobool [:grep "return abcasz" pattern="a.c"]]  
abcasz
# true
