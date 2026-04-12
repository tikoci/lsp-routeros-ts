# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/21
# Post author: @rextended
# Extracted from: code-block

:global hex2bin do={
    :local conv $1
    :if (!($conv~"(^0x|^)[0-9a-fA-F]+\$")) do={:return "00000000"}
    :if ([:typeof [:find $conv "0x" -1]] = "nil") do={:set conv "0x$conv"}
    :local number [:tonum $conv]
    :local ret    ""
    :local rshift 7
    :if ($number >       0xFF) do={:set rshift 15}
    :if ($number >     0xFFFF) do={:set rshift 31}
    :if ($number > 0xFFFFFFFF) do={:set rshift 63}
    :for i from=0 to=$rshift step=1 do={
        :set ret "$(($number >> $i) & 1)$ret"
    }
    :return $ret
}
