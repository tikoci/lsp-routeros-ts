# Source: https://forum.mikrotik.com/t/how-to-covert-int-to-hex-type-value-and-save-it-in-a-string/52654/5
# Post author: @rextended
# Extracted from: code-block

:global lazyvar "FF85"
:set lazyvar [:tonum ("0x".$lazyvar)]
:if ($lazyvar > 32767) do={:set lazyvar ($lazyvar - 65536)}
:put $lazyvar
:set lazyvar
