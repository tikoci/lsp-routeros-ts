# Source: https://forum.mikrotik.com/t/cleaning-characters-from-string-for-use-in-variablename/139391/4
# Topic: Cleaning characters from string for use in variablename
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
global myFuncPresent "Do not manually remove any lines with the wordpart 'Func' in them!!"
} 
{
 global replaceCharacterFunc do={
  while condition=[find $1 $2] do={
   set $1 ("$[pick $1 0 ([find $1 $2]) ]".$3."$[pick $1 ([find $1 $2]+1) ([len $1])]")}
  return $1
 }
}
