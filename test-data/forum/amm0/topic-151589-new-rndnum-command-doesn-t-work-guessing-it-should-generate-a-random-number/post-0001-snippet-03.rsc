# Source: https://forum.mikrotik.com/t/new-rndnum-command-doesnt-work-guessing-it-should-generate-a-random-number/151589/1
# Topic: New ":rndnum" command doesn't work (& guessing it should generate a random number)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{:local results {""}; :for from=1 to=100 counter=x do={:set ($results->$x) [:rndnum from=1 to=100]}; :put $results;}

;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1
;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1
