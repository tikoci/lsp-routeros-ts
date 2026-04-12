# Source: https://forum.mikrotik.com/t/how-to-add-color-to-output/142687/6
# Topic: How to add color to output
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global RED     do={/terminal style error}
:global BLUE    do={/terminal style ambiguous}
:global WHITE   do={/terminal style "syntax-old"}
:global blue    do={/terminal style escaped} 
:global cyan    do={/terminal style "varname-local"}  
:global red     do={/terminal style varname} 
:global plain   do={/terminal style "syntax-val" } 
:global yellow  do={/terminal style "syntax-meta"}  
:global strong  do={/terminal style "syntax-noterm"}
:global nostyle do={/terminal style "none"}
