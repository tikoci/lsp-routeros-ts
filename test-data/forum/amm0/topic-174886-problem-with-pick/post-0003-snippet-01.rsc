# Source: https://forum.mikrotik.com/t/problem-with-pick/174886/3
# Topic: Problem with :pick
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global ipaddresses [/queue simple get [find name=queue1] target]
:global ipaddress [:pick $ipaddresses 0 ] 
:global cidrmark [:find  $ipaddress "/"]
:put "$[:pick $ipaddress 0 $cidrmark]"
