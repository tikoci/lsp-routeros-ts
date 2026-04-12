# Source: https://forum.mikrotik.com/t/chateau-5g-ax-automatic-cellular-reconnect-on-provider-disconnect/164421/4
# Topic: Chateau 5G ax - Automatic cellular reconnect on provider disconnect
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system logging action add name=support target=memory memory-lines=16384
/system logging remove [find where topics~"lte"]
/system logging add action=support topics=lte,!raw,!packet
