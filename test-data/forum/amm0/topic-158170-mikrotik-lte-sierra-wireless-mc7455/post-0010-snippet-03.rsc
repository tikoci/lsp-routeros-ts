# Source: https://forum.mikrotik.com/t/mikrotik-lte-sierra-wireless-mc7455/158170/10
# Topic: MikroTik LTE Sierra Wireless MC7455
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/lte/at-chat [find] input="AT!GPSAUTOSTART?"

output:   function:  1
            fixtype: 1
            maxtime: 255 seconds
            maxdist: 1000 meters
            fixrate: 1 seconds
          OK
