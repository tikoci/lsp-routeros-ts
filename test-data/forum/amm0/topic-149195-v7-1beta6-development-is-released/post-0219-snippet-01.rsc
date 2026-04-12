# Source: https://forum.mikrotik.com/t/v7-1beta6-development-is-released/149195/219
# Topic: v7.1beta6 [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/lte/at-chat lte2 input="AT!LTEINFO\?"      
  output: !LTEINFO: Serving: EARFCN MCC MNC TAC CID Bd D U SNR PCI RSRQ RSRP RSSI RXLV 2100 311 480 7939 007A230C 4 3 3 -10 390 -11.1 -70.9 -42.6 53 
          IntraFreq: PCI RSRQ RSRP RSSI RXLV 390 -11.1 -70.9 -42.6 53 374 -19.0 -79.2 -50.2 53 InterFreq: EARFCN ThresholdLow ThresholdHi Priority PCI RSRQ 
          RSRP RSSI RXLV GSM: ThreshL ThreshH Prio NCC ARFCN 1900 valid BSIC RSSI RXLV WCDMA: UARFCN ThreshL ThreshH Prio PSC RSCP ECN0 RXLV CDMA 1x: Chan BC 
          Offset Phase Str CDMA HRPD: Chan BC Offset Phase Str OK

 /interface/lte/at-chat lte2 input="AT!GSTATUS\?"                      
  output: !GSTATUS: Current Time: 5268 Temperature: 38 Bootup Time: 0 Mode: ONLINE System mode: LTE PS state: Attached LTE band: B4 LTE bw: 10 MHz LTE Rx 
          chan: 2100 LTE Tx chan: 20100 EMM state: Registered Normal Service RRC state: RRC Connected IMS reg state: No Srv IMS mode: Normal RSSI (dBm): -41 
          Tx Power: 0 RSRP (dBm): -71 TAC: 1F03 (7939) RSRQ (dB): -15 Cell ID: 00... (80...) SINR (dB): 15.0 OK
