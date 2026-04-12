# Source: https://forum.mikrotik.com/t/v7-18beta-testing-is-released/181371/213
# Topic: v7.18beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:serialize file-name=raid1/connections.csv to=dsv delimiter="," options=dsv.remap [/ip/firewall/connection print detail as-value]
:local isoexpire [:toarray [:serialize to=json ([:timestamp] + 1d) ] ] 
:local fsid [/ip/cloud/file-share/add expires=$isoexpire path=raid1]
:delay 15s
:put "CSV file with connections: $[ /ip/cloud/file-share get $fsid url ]/connections.csv?dl"
}
