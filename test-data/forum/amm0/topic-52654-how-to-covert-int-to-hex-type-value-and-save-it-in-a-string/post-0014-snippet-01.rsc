# Source: https://forum.mikrotik.com/t/how-to-covert-int-to-hex-type-value-and-save-it-in-a-string/52654/14
# Topic: How to covert int to hex type value and save it in a string?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global "numbyte2hex-using-convert" do={
    :return [:convert from=byte-array to=hex {$1}]
}

:put [$"numbyte2hex-using-convert" 255]
# ff
