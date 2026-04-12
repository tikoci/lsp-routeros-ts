# Source: https://forum.mikrotik.com/t/fakeal-script-to-statistically-generate-random-ips-in-address-list/168494/1
# Topic: $FAKEAL - script to statistically generate random IPs in address-list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

$FAKEAL spread=2000 density=30 list=rndvente start=10.20.0.0     
using   address-list rndvente
remove  rndvente done   
adding  99%     10.27.192.84 (added 126471 at 507988 of 508000)              
runtime 00:02:09
done!   wanted 152400 got 126471 (off by 25929) in rndvente (length 126471)
