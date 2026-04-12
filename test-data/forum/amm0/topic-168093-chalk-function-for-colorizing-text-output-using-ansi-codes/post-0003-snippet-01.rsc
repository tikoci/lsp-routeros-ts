# Source: https://forum.mikrotik.com/t/chalk-function-for-colorizing-text-output-using-ansi-codes/168093/3
# Topic: $CHALK - function for colorizing text output using ANSI codes
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    :local myprint do={
       :global CHALK
       :put "$[$CHALK yellow]Hello $[$CHALK yellow inverse=yes]Kentzo$[$CHALK reset]"
   }
   
   $myprint
}
