# Source: https://forum.mikrotik.com/t/a-few-undocumented-operators-that-are-kind-of-neat/163557/11
# Topic: A few undocumented operators that are kind of neat.
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global fn do={:global fn; $fn}                      
:put $fn                       
          # output:      ;(evl (evl /globalname=$fn) (<%% $fn (> $fn)))
:global fn do={:global fn; [$fn]}                      
:put $fn                       
          # output:      ;(evl (<%% (evl (evl /globalname=$fn);(<%% $fn (> $fn))) ))
