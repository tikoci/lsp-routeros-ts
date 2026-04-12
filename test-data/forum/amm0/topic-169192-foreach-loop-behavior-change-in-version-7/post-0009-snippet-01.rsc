# Source: https://forum.mikrotik.com/t/foreach-loop-behavior-change-in-version-7/169192/9
# Topic: "foreach loop" behavior change in version 7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global myarray {a=1;child={ca=2}}
:global mysubarray ($myarray->"child")
:set ($mysubarray->"ca") 1
