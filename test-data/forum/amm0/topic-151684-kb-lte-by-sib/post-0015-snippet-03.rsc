# Source: https://forum.mikrotik.com/t/kb-lte-by-sib/151684/15
# Topic: KB: LTE by SiB
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[admin@DeltaAlpha] > $AT "AT#FIRMWARE"
HOST FIRMWARE  : 32.00.005_1
MODEM FIRMWARE : 4
INDEX  STATUS     CARRIER  VERSION         TMCFG  CNV       LOC
1                 Generic  32.00.115       1025   empty     1
2      Activated  Verizon  32.00.124       2020   empty     2
3                 ATT      32.00.144       4021   empty     3
4                 TMUS     32.00.153       5004   empty     4

[admin@DeltaAlpha] > /interface/lte/at-chat [find running]  input="AT#FIRMWARE"
  output: HOST FIRMWARE : 32.00.005_1 MODEM FIRMWARE : 4 INDEX STATUS CARRIER VERSION TMCFG CNV LOC 1 Generic 32.00.115 1025 empty 1 2 Activated 
          Verizon 32.00.124 2020 empty 2 3 ATT 32.00.144 4021 empty 3 4 TMUS 32.00.153 5004 empty 4 OK
