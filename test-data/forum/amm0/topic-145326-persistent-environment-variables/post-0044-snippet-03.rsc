# Source: https://forum.mikrotik.com/t/persistent-environment-variables/145326/44
# Topic: Persistent Environment Variables
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global shortThanToArray (>{})
:put "$shortThanToArray $[:typeof $shortThanToArray] $[:len $shortThanToArray]" 
 # array 0
