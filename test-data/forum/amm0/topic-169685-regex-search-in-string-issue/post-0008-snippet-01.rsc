# Source: https://forum.mikrotik.com/t/regex-search-in-string-issue/169685/8
# Topic: Regex search in String Issue
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global findHostInJson do={:local s ([:find $x "hostname"]+11); :local r [:pick $x $s 65000]; :local l [:find $r "\""]; :local rv [:pick $r 0 $l]; :return "$rv"}
:global myoutput [/tool/fetch url=... as-value output=user ...]
:put [$findHostInJson ($myoutput->"data")]
