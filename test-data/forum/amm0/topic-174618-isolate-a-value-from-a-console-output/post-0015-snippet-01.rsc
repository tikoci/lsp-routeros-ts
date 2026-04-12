# Source: https://forum.mikrotik.com/t/isolate-a-value-from-a-console-output/174618/15
# Topic: Isolate a value from a console output
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global getInterfaceIP do={
   :local currentIPv4 [/ip address get [find interface~$1] address]
   :return [:pick $currentIPv4 0 [:find $currentIPv4 "/" -1]]
}

:put [$getInterfaceIP ether1]
