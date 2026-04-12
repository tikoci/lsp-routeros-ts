# Source: https://forum.mikrotik.com/t/the-issue-of-a-function-containing-variables-unsuccessfully/176376/13
# Topic: The issue of a function containing variables unsuccessfully.
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global DisableNatDns do={ /ip/firewall/nat set [find comment~"hack_dns"] disabled=$1 }
$DisableNatDns yes
$DisableNatDns no
