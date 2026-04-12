# Source: https://forum.mikrotik.com/t/v7-18beta-testing-is-released/181371/38
# Topic: v7.18beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# output /ip/firewall/connection using :serialize...
# using tab to console
:put [:serialize to=dsv delimiter="\t" options=dsv.remap  [/ip/firewall/connection/print as-value]]          
# CSV to file
:serialize to=dsv delimiter="," options=dsv.remap [/ip/firewall/connection/print as-value] file-name=connections.csv
