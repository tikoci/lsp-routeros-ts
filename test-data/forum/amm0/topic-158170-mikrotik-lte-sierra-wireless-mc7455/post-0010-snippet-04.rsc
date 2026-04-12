# Source: https://forum.mikrotik.com/t/mikrotik-lte-sierra-wireless-mc7455/158170/10
# Topic: MikroTik LTE Sierra Wireless MC7455
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/lte/at-chat [find] input="AT!GPSAUTOSTART=?"

output: !GPSAUTOSTART: <function>[,<fixtype>,<maxtime>,<maxdist>,<fixrate>]
          <function>:  0-Disabled, 1-On bootup, 2-When NMEA port opened
          <fixtype>: 1-Standalone, 2-MS-Based, 3-MS-Assisted
          <maxtime>: 1-255 seconds
          <maxdist>: 1-4294967280 meters
          <fixrate>: 1-65535 seconds
          OK
