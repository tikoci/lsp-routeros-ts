# Source: https://forum.mikrotik.com/t/backup-config-to-gmail-v1-7/156147/2
# Topic: Backup config to Gmail v1.7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local vermajor [:tonum [:pick [/system resource get version] 0 1]]
:if ($vermajor > 6) do={ [:parse "export show-sensitive file=backup.rsc"] } else={ :export file=backup.rsc }
}
