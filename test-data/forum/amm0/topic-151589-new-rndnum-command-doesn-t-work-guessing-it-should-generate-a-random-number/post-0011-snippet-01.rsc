# Source: https://forum.mikrotik.com/t/new-rndnum-command-doesnt-work-guessing-it-should-generate-a-random-number/151589/11
# Topic: New ":rndnum" command doesn't work (& guessing it should generate a random number)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [:typeof [:rndnum to=1 from=100]]
num
:put [:typeof [:rndstr length=8 from=01234567890]]
str
