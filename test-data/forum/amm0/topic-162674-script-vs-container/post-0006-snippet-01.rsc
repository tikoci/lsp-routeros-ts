# Source: https://forum.mikrotik.com/t/script-vs-container/162674/6
# Topic: Script VS Container
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global mytag "pihole"
/container stop [find tag~$mytag]
:do { :delay 1s } while=([/container get [find tag~$mytag] status ]!="stopped")
/container remove [find tag~$mytag]
