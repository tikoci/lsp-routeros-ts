# Source: https://forum.mikrotik.com/t/find-addresses-with-same-octets/168376/27
# Topic: find addresses with same octets
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# to see how slow on-error= is, use higher density= 
# which means a greater chance that random IP is already present...
# code will re-try another random IP, but as more IP...
# but harder to find unique one randomly

$fantasylist spread=1 density=75 fidelity=2

     remove  previous list: $fantasylist
     adding  169.254.0.176   in $fantasylist (29 / 190)
     skipping number 29 - no unique random ip after 2 tries (perhaps use fidelity=4)
     adding  169.254.0.201   in $fantasylist (44 / 190)
     skipping number 44 - no unique random ip after 2 tries (perhaps use fidelity=4)
     adding  169.254.0.112   in $fantasylist (55 / 190)
          [...]
     done! requested 190 and added 161 random IPs (off by 29) to $fantasylist (len=161) after 00:01:06.894532020
