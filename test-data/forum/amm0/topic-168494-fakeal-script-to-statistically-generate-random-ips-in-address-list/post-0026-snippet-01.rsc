# Source: https://forum.mikrotik.com/t/fakeal-script-to-statistically-generate-random-ips-in-address-list/168494/26
# Topic: $FAKEAL - script to statistically generate random IPs in address-list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

$FAKEAL spread=5000 density=10 list=rndtens start=10.10.0.0 replace=no   
    using   address-list rndtens
    adding  99%     10.29.96.2191   (added 126138 at 1269979 of 1270000)             
    skipped 136 IPs, likely because the IP was already in list
    runtime 00:02:49
    done!   wanted 127000 got 126138 off by 862 (0%) in rndtens (length 127405)
