# Source: https://forum.mikrotik.com/t/v7-1beta6-development-is-released/149195/219
# Topic: v7.1beta6 [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/lte>> at-chat lte1 input="AT#RFSTS" 
  output: #RFSTS: "310 410",800,-93,-59,-14,8B1E,255,-5,1280,19,2,A20...,"310410...","AT&T",3,2
OK

/interface/lte>> at-chat lte1 input="AT#moni"     
  output: #MONI: AT&T RSRP:-92 RSRQ:-17 TAC:8B1E Id:A204... EARFCN:800 PWR:-54dbm DRX:1280
