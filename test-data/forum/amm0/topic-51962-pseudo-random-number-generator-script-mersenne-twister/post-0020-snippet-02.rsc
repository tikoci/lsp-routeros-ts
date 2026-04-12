# Source: https://forum.mikrotik.com/t/pseudo-random-number-generator-script-mersenne-twister/51962/20
# Topic: Pseudo Random Number Generator Script (Mersenne Twister)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# Note: $RNDORGINT returns a string at present, (:typeof [$RNDORGINT])="str"

# default is min=1 max=1000 base=10
:put [$RNDORGINT].
# 449

:put [$RNDORGINT min=1 max=2]
# 1

:put [$RNDORGINT min=1000 max=9999]
# 4803

# base can be 2, 8, 10, or 16
:put [$RNDORGINT min=1000 max=9999 base=2]
00101011000011

# negative numbers
:put [$RNDORGINT min=-10 max=0]
# -3
