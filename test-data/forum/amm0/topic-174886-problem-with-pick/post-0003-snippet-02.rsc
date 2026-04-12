# Source: https://forum.mikrotik.com/t/problem-with-pick/174886/3
# Topic: Problem with :pick
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local ipaddress ([/queue simple get [find name=queue1] target]->0); 
:put "$[:pick $ipaddress 0 [:find  $ipaddress /]]"
}
