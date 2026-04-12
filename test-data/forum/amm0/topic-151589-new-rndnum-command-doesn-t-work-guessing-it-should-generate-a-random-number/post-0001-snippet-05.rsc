# Source: https://forum.mikrotik.com/t/new-rndnum-command-doesnt-work-guessing-it-should-generate-a-random-number/151589/1
# Topic: New ":rndnum" command doesn't work (& guessing it should generate a random number)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[skyfi@bigdude] > :put [:rndnum from=1.0 to=2.0]
16777216
[skyfi@bigdude] > :put [:rndnum from=1.0 to=10.0]
16777216
[skyfi@bigdude] > :put [:rndnum from=0 to=1.0]
0
