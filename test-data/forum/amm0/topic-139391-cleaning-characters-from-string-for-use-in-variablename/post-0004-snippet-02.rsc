# Source: https://forum.mikrotik.com/t/cleaning-characters-from-string-for-use-in-variablename/139391/4
# Topic: Cleaning characters from string for use in variablename
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global replaceCharacterFunc do={
    :local a [tostr $1]
    :local b $char
    :if ([typeof $b]="nil") do={:set b "-"}
    :while ([find $a $b]) do={
        :set $a ("$[:pick $a 0 ([find $a $b]) ]"."$[:pick $a ([find $a $b]+1) ([:len $a])]")}
    :return $a
}
