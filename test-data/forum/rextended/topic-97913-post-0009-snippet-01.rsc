# Source: https://forum.mikrotik.com/t/how-to-convert-a-hex-value-to-a-char/97913/9
# Post author: @rextended
# Extracted from: code-block

[rextended@MATRIX] > :global hex2chr do={:return [[:parse "(\"\\$1\")"]]}
[rextended@MATRIX] > :put [$hex2chr 64]
d
[rextended@MATRIX] >
