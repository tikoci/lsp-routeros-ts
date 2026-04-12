# Source: https://forum.mikrotik.com/t/put-problem-in-scripting/126381/17
# Topic: ":put" problem in scripting
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global arrarr {a=1;b="txt"}
:put "$arrarr"
#a=1;b=txt
:put "some text $arrarr"
# ### no output as seen elsewhere in thread ###
