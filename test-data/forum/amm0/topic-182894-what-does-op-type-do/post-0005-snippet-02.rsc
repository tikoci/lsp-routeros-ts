# Source: https://forum.mikrotik.com/t/what-does-op-type-do/182894/5
# Topic: What does op type (>[ ... ]) do?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# version 1
(evl / (evl /localname=$x;value=1) (evl /localdo=;(evl (evl /putmessage=$x));name=$fn) (<%% $fn (> $fn)))
# version 2
(evl / (evl /localname=$x2;value=2) (evl /localname=$fn2;value=(> (evl (evl /putmessage=$x2)))) (<%% $fn2 (> $fn2)))
