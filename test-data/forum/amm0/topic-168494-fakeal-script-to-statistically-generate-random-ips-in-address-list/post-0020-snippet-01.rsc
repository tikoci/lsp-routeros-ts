# Source: https://forum.mikrotik.com/t/fakeal-script-to-statistically-generate-random-ips-in-address-list/168494/20
# Topic: $FAKEAL - script to statistically generate random IPs in address-list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

$FAKEAL spread=254 density=25 list=test_Start start=172.25.0.0  
using   address-list test_Start
remove  test_Start done   
adding  100%    172.25.252.347  (added 16029 at 64515 of 64516)             
runtime 00:00:16
done!   wanted 16129 got 16029 off by 100 (0%) in test_Start (length 16029)

$ippa
before @rextended aggregation there are 16029 IPs
completed in 01:02:58.130963720
after @rextended aggregation there are 13938 IP
