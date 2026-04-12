# Source: https://forum.mikrotik.com/t/at-commands-to-modem-in-mbim-mode/140952/16
# Topic: AT Commands to modem in MBIM mode?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[skyfi@hap94] > /interface/lte/monitor lte1 
            status: connected
             model: MC7455
          revision: SWI9X30C_02.32.11.00
  current-operator: AT&T
        data-class: LTE
    session-uptime: 3h42m9s
              imei: xxx
              imsi: xxx
              uicc: xxx
              rssi: -91dBm

[skyfi@hap94] > /interface/lte/at-chat lte1 input="AT!ENTERCND=\"A710\""
  output: OK

[skyfi@hap94] > /interface/lte/at-chat lte1 input="AT!USBCOMP=?"
  output: !USBCOMP: AT!USBCOMP=<Config Index>,<Config Type>,<Interface bitmask> 
          <Config Index> - configuration index to which the composition applies, 
          should be 1 <Config Type> - 1:Generic, 2:USBIF-MBIM, 3:RNDIS config 
          type 2/3 should only be used for specific Sierra PIDs: 68B1, 9068 
          customized VID/PID should use config type 1 <Interface bitmask> - DIAG 
          - 0x00000001, NMEA - 0x00000004, MODEM - 0x00000008, RMNET0 - 
          0x00000100, RMNET1 - 0x00000400, MBIM - 0x00001000, e.g. 10D - diag, 
          nmea, modem, rmnet interfaces enabled 1009 - diag, modem, mbim 
          interfaces enabled The default configuration is: at!usbcomp=1,1,10F OK

[skyfi@hap94] > /interface/lte/at-chat lte1 input="AT!LTEINFO?"
  output: !LTEINFO: Serving: EARFCN MCC MNC TAC CID Bd D U SNR PCI RSRQ RSRP 
          RSSI RXLV 2000 310 410 35614 0A1FC518 4 3 3 6 269 -12.1 -94.6 -65.8 -- 
          IntraFreq: PCI RSRQ RSRP RSSI RXLV 269 -12.1 -94.6 -65.8 -- 223 -18.0 
          -103.3 -72.5 -- 222 -20.0 -106.0 -72.5 -- InterFreq: EARFCN 
          ThresholdLow ThresholdHi Priority PCI RSRQ RSRP RSSI RXLV 5110 0 0 0 
          290 -15.0 -93.3 -65.2 0 5110 0 0 0 8 -9.0 -83.2 -65.9 0 5110 0 0 0 125 
          -14.7 -90.9 -66.0 0 WCDMA: UARFCN ThreshL ThreshH Prio PSC RSCP ECN0 
          RXLV OK

[skyfi@hap94] > /interface/lte/at-chat lte1 input="AT!GSTATUS?"
  output: !GSTATUS: Current Time: 12834 Temperature: 47 Reset Counter: 1 Mode: 
          ONLINE System mode: LTE PS state: Attached LTE band: B4 LTE bw: 10 MHz 
          LTE Rx chan: 2000 LTE Tx chan: 20000 LTE CA state: INACTIVE LTE Scell 
          band:B12 LTE Scell bw:10 MHz LTE Scell chan:5110 EMM state: Registered 
          Normal Service RRC state: RRC Connected IMS reg state: No Srv PCC RxM 
          RSSI: -65 RSRP (dBm): -98 PCC RxD RSSI: -64 RSRP (dBm): -94 SCC RxM 
          RSSI: -65 RSRP (dBm): -90 SCC RxD RSSI: -71 RSRP (dBm): -96 Tx Power: 
          -- TAC: 8B1E (35614) RSRQ (dB): -10.5 Cell ID: 0A1FC518 (169854232) 
          SINR (dB): 7.6 OK

[skyfi@hap94] > /interface/lte/at-chat lte1 input="AT!USBCOMP?"
  output: Config Index: 1 Config Type: 1 (Generic) Interface bitmask: 00001009 
          (diag,modem,mbim) OK

[skyfi@hap94] > /system/routerboard/print 
       routerboard: yes
        board-name: hAP ac^2
             model: RBD52G-5HacD2HnD
     serial-number: xxx
     firmware-type: ipq4000L
  factory-firmware: 6.43.10
  current-firmware: 7.1rc2
  upgrade-firmware: 7.1rc2
