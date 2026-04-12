# Source: https://forum.mikrotik.com/t/copy-firewall-rules-and-settings/266277/3
# Topic: Copy Firewall Rules and settings
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global allowAddress do={
    :if ($position > 0) do={
        /ip/firewall/filter add action=accept chain=input dst-address=$address place-before=$position 
    } else={
        /ip/firewall/filter add action=accept chain=input dst-address=$address
    }
}
