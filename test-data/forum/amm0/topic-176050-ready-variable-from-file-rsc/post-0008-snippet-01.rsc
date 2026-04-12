# Source: https://forum.mikrotik.com/t/ready-variable-from-file-rsc/176050/8
# Topic: Ready variable from file.rsc
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local hotspotconfig [:deserialize from=json [/file/get myhotspotconfig.json contents]]
:put ($hotspotconfig->"user")
:put ($hotspotconfig->"company")
}
