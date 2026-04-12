# Source: https://forum.mikrotik.com/t/update-a-variable-with-a-function/176277/2
# Topic: Update a variable with a function
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
     :local confirmkey [/terminal/inkey timeout=1m] 
     :if ($confirmkey=89 or $confirmkey=121) do={ :put "got Y or y" } else={:put "got something else"}  
}
