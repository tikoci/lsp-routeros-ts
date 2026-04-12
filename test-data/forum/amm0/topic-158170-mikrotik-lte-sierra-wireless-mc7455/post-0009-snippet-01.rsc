# Source: https://forum.mikrotik.com/t/mikrotik-lte-sierra-wireless-mc7455/158170/9
# Topic: MikroTik LTE Sierra Wireless MC7455
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:while (1) do={
:put "\1Bc" 
/interface/lte at-chat [find] input="AT!GSTATUS?"
/interface/lte at-chat [find] input="AT!LTEINFO?"
:put "\r\nUse Ctrl-C to stop"
:delay 2s
}
