# Source: https://forum.mikrotik.com/t/update-a-variable-with-a-function/176277/2
# Topic: Update a variable with a function
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
     :local confirmkey [:convert from=byte-array to=raw {[/terminal/inkey]}]
     :if ($confirmkey~"[yY]") do={ :put "got Y or y" } else={:put "got something else"}  
}
