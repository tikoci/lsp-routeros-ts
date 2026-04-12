# Source: https://forum.mikrotik.com/t/v7-11beta-testing-is-released/167585/24
# Topic: v7.11beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
  :put "$[/terminal style escape]Press any key to exit loop"; 
  :local keypress 0xFFFF;
  while (keypress=0xFFFF) do={ 
      :put "$[/terminal style none]$[:rndstr]" 
      /terminal cuu    
      :set keypress [/terminal inkey timeout=1s]
  }
}
