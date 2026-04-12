# Source: https://forum.mikrotik.com/t/checking-recursive-route-values/167746/7
# Topic: Checking Recursive Route values
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
# ordered listed are declared using {} with ; inbetween & can be any type
:local orderedList {"cat";"dog";3;8.8.8.8}

:put ($orderedList->0)
#cat
:put ($orderedList->1) 
#dog
:put ($orderedList->2) 
#3
:put [:typeof ($orderedList->3)] 
#ip
:put [:typeof ($orderedList->4)] 
#nothing -since there isn't one, it's type is actually a [i]nothing[/i] type, NOT string or anything...
}
