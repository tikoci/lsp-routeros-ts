# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/17
# Post author: @rextended
# Extracted from: code-block

:global hex2bin do={
    :local conv $1
    :if (!($conv~"(^0x|^)[0-9a-fA-F]{2}\$")) do={:return "00000000"}
    :if ([:typeof [:find $conv "0x" -1]] = "nil") do={:set conv "0x$conv"}
    :local number [:tonum $conv]
    :local b8 0 ; :if ($number & 128) do={:set b8 1}
    :local b7 0 ; :if ($number &  64) do={:set b7 1}
    :local b6 0 ; :if ($number &  32) do={:set b6 1}
    :local b5 0 ; :if ($number &  16) do={:set b5 1}
    :local b4 0 ; :if ($number &   8) do={:set b4 1}
    :local b3 0 ; :if ($number &   4) do={:set b3 1}
    :local b2 0 ; :if ($number &   2) do={:set b2 1}
    :local b1 0 ; :if ($number &   1) do={:set b1 1}
    :return "$b8$b7$b6$b5$b4$b3$b2$b1"
}
