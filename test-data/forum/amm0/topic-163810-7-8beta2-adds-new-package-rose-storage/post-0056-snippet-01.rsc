# Source: https://forum.mikrotik.com/t/7-8beta2-adds-new-package-rose-storage/163810/56
# Topic: 7.8beta2 adds new package ROSE-storage
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global path "/nfs1/images/disk1"
# ...
/container add file=[:pick "$(path)/$(containername).tar" 1 999] ...
