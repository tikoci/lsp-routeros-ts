# Source: https://forum.mikrotik.com/t/find-addresses-with-same-octets/168376/37
# Topic: find addresses with same octets
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

>      $FAKEAL list=test_Start spread=16 density=75; $Pippa

using   address-list test_Start
remove  test_Start done   
adding  100%    169.254.15.223 (added 2050 at 4063 of 4064)             
runtime 00:00:01
done!   wanted 3048 got 2050 (off by 998) in test_Start (length 2050)
before @rextended aggregation there are 2050 IPs
completed in 00:00:53.501365120
after @rextended aggregation there are 1502 IP
