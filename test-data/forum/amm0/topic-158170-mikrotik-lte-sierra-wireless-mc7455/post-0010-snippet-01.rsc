# Source: https://forum.mikrotik.com/t/mikrotik-lte-sierra-wireless-mc7455/158170/10
# Topic: MikroTik LTE Sierra Wireless MC7455
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# use LTE "DIV" antenna to receive GPS signal:
/interface/lte/at-chat [find] input="AT!CUSTOM=\”GPSSEL\”,1"
# OR... to use the GPS u.FL on modem to a seperate GPS antennas:
/interface/lte/at-chat [find] input="AT!CUSTOM=\”GPSSEL\”,0"
