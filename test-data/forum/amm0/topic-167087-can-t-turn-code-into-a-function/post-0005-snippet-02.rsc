# Source: https://forum.mikrotik.com/t/cant-turn-code-into-a-function/167087/5
# Topic: Can't turn code into a function
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local rv [$reverseNumber ABCD as-array] 
:put $rv 
:put [:typeof $rv]
:set rv [$reverseNumber ABCD]
:put $rv 
:put [:typeof $rv]} 
}

# Output:
B;A;D;C
array
BADC
str
