# Source: https://forum.mikrotik.com/t/simple-querys-output-to-variable/168589/2
# Topic: Simple querys output to variable
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
   :local porttext; 
   /port
   :foreach p in=[find] do={ 
            :set porttext "$porttext $[get $p name] $[get $p data-bits]-$[:pick [get $p parity] 0 1]-$[get $p stop-bits] $[get $p baud-rate] (use: $[get $p used-by])\r\n" 
   }
   :put "$porttext"
}
