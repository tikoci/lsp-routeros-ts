# Source: https://forum.mikrotik.com/t/modify-files-inside-mikrotik/179159/14
# Topic: modify files inside mikrotik
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global replacedContent [$STR replace [/file get FILENAME contents] "http://" "https://"]
# to see the output
:put $replacedContent
# to save output to a new file
/file add name=NEWFILENAME
/file set NEWFILENAME contents=$replacedContent
# if it wanted same file  - which is bad for testing - don't need the /file add
# /file set FILENAME contents=$replacedContent
