# Source: https://forum.mikrotik.com/t/v7-15beta-testing-is-released/174120/232
# Topic: v7.15beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/file print file="name with spaces"
/file set "name with spaces" contents="it works"
:put [/file get "name with spaces" contents]
# it works
