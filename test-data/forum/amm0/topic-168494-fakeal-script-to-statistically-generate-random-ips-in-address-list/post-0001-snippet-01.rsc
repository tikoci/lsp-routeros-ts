# Source: https://forum.mikrotik.com/t/fakeal-script-to-statistically-generate-random-ips-in-address-list/168494/1
# Topic: $FAKEAL - script to statistically generate random IPs in address-list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[admin@router] />        $FAKEAL spread=1 density=1

using   address-list FAKEAL
remove  FAKEAL done   
adding  98%     169.254.0.250 (added 4 at 250 of 254)             
runtime 00:00:00
done!   wanted 2 got 4 (off by -2) in FAKEAL (length 4)

[admin@router] />      /ip/firewall/address-list print
Columns: LIST, ADDRESS, CREATION-TIME
# LIST    ADDRESS        CREATION-TIME      
0 FAKEAL  169.254.0.65   2023-08-01 13:28:46
1 FAKEAL  169.254.0.81   2023-08-01 13:28:46
2 FAKEAL  169.254.0.102  2023-08-01 13:28:46
3 FAKEAL  169.254.0.250  2023-08-01 13:28:46
