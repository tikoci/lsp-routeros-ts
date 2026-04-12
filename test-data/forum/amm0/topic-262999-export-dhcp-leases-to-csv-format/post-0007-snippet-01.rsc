# Source: https://forum.mikrotik.com/t/export-dhcp-leases-to-csv-format/262999/7
# Topic: Export DHCP leases to CSV format
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:serialize to=dsv delimiter="\t" options=dsv.remap \
    [/ip/dhcp-server/lease/print detail as-value] \
    order=address,mac-address,client-id,server,host-name,comment \
    file-name="dhcp-leases-$[/system/identity get name].csv.txt"
