# Source: https://forum.mikrotik.com/t/at-commands-to-modem-in-mbim-mode/140952/17
# Topic: AT Commands to modem in MBIM mode?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[skyfi@hap94] > /system/scheduler/export

# sep/01/2021 18:33:32 by RouterOS 7.1rc2
# software id = QDR7-4Y0A
#
# model = RBD52G-5HacD2HnD
# serial number = xxx
/system scheduler
add interval=15s name=doPollingScripts on-event=":global AT;\r\
    \n:global atLTEINFO;\r\
    \n:global lteinfo;\r\
    \n\r\
    \n:global AT do={/interface/lte/at-chat lte1 input=\$1;};\r\
    \n:global atLTEINFO [/interface/lte/at-chat lte1 input=\"AT!LTEINFO\?\" as-va\
    lue];\r\
    \n:global lteinfo do={ :put \$atLTEINFO };" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-time=\
    startup
    
[skyfi@hap94] > $AT ATI
  output: Manufacturer: Sierra Wireless, Incorporated Model: MC7455 Revision: 
          SWI9X30C_02.32.11.00 r8042 CARMD-EV-FRMWR2 2019/05/15 21:52:20 MEID: 
          xxx IMEI: xxx IMEI SV: 19 FSN: xxx 
          +GCAP: +CGSM OK

[skyfi@hap94] > $lteinfo
output=!LTEINFO: 
Serving:   EARFCN MCC MNC   TAC      CID Bd D U SNR PCI  RSRQ   RSRP   RSSI RXLV
             2000 310 410 35614 0A1FC518  4 3 3  -3 269 -12.6 -100.7  -68.6 --
IntraFreq:                                          PCI  RSRQ   RSRP   RSSI RXLV
                                                    269 -12.6 -100.7  -68.6 --
                                                     40 -14.1 -101.4  -78.4 --
                                                    223 -17.6 -106.0  -78.4 --
InterFreq: EARFCN ThresholdLow ThresholdHi Priority PCI  RSRQ   RSRP   RSSI RXLV
             5110            0           0        0 290 -15.8  -99.2  -71.9   0
             5110            0           0        0  33 -19.0  -97.1  -68.9   0
             5110            0           0        0   8 -11.7  -91.3  -70.1   0
WCDMA:     UARFCN ThreshL ThreshH Prio PSC   RSCP  ECN0 RXLV

OK
