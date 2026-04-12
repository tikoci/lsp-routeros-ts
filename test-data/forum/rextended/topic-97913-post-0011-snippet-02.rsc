# Source: https://forum.mikrotik.com/t/how-to-convert-a-hex-value-to-a-char/97913/11
# Post author: @rextended
# Extracted from: code-block

{
:global hex2chr do={:return [[:parse "(\"\\$1\")"]]}
:put [$hex2chr "3D"]


:local key "3D"
:local char [[:parse "(\"\\$[:pick "0123456789ABCDEF" (($key >> 4) & 0xF)]$[:pick "0123456789ABCDEF" ($key & 0xF)]\")"]]
:put $char
}
