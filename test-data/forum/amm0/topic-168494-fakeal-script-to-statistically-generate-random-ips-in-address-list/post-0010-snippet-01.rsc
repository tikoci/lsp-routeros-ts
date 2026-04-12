# Source: https://forum.mikrotik.com/t/fakeal-script-to-statistically-generate-random-ips-in-address-list/168494/10
# Topic: $FAKEAL - script to statistically generate random IPs in address-list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

$FAKEAL spread=254 density=1 list=rndtens start=10.10.0.0
     using   address-list rndtens
     remove  rndtens done   
     adding  99%     10.10.251.697   (added 632 at 64325 of 64516)             
     runtime 00:00:03
     done!   wanted 645 got 632 off by 13 (2%) in rndtens (length 632)

$FAKEAL spread=254 density=25 list=test_Start start=172.25.0.0  
     using   address-list test_Start
     remove  test_Start done   
     adding  100%    172.25.252.347  (added 16029 at 64515 of 64516)             
     runtime 00:00:16
     done!   wanted 16129 got 16029 off by 100 (0%) in test_Start (length 16029)
