# Source: https://forum.mikrotik.com/t/update-a-variable-with-a-function/176277/2
# Topic: Update a variable with a function
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local resp [/terminal/ask prompt="Continue? [y/n]"]
:if ($resp~"^[yY]\$") do={:put "got Y or y"} else={:put "got something else"}
}
