# Source: https://forum.mikrotik.com/t/v7-1beta6-development-is-released/149195/217
# Topic: v7.1beta6 [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/lte> monitor lte1,lte2
              status: connected            connected
               model: LM960A18             MC7354
            revision: 32.00.144            SWI9X15C_05.05.58.01
    current-operator: AT&T                 Verizon
          data-class: LTE                  LTE
      session-uptime: 1h33m40s             1h28m28s
                imei: 356299100000000      359225050000000
                imsi: 310410000000000      311480000000000
                uicc: 89014100000000000000 89148000000000000000
                rssi: -93dBm               -75dBm

/interface/lte> /interface/monitor-traffic lte1,lte2
                         name:       lte1      lte2
        rx-packets-per-second:      2 409     4 440
           rx-bits-per-second:   13.0Mbps  25.2Mbps
     fp-rx-packets-per-second:      2 409     4 440
        fp-rx-bits-per-second:   13.0Mbps  25.2Mbps
          rx-drops-per-second:          0         0
         rx-errors-per-second:          0         0
        tx-packets-per-second:        547     1 083
           tx-bits-per-second:  285.6kbps 625.4kbps
     fp-tx-packets-per-second:          0         0
        fp-tx-bits-per-second:       0bps      0bps
          tx-drops-per-second:          0         0
    tx-queue-drops-per-second:          0         0
         tx-errors-per-second:          0         0
