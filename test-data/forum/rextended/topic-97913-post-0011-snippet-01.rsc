# Source: https://forum.mikrotik.com/t/how-to-convert-a-hex-value-to-a-char/97913/11
# Post author: @rextended
# Extracted from: code-block

:local char [[:parse "(\"\\$[:pick "0123456789ABCDEF" (($key >> 4) & 0xF)]$[:pick "0123456789ABCDEF" ($key & 0xF)]\")"]]
