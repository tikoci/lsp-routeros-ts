# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/18
# Post author: @rextended
# Extracted from: code-block

:global bin2hex do={
    :local bin $1
    :local dec  0
    :local mol  1
    :if (!($bin~"^[0-1]{8}\$")) do={:return "0x00"}
    :for pos from=1 to=8 do={
        :local temp [:tonum [:pick $bin (8 - $pos) (8 - $pos + 1)]]
        :set dec ($dec + ($temp * $mol))
        :set mol ($mol * 2)
    }
    :local hexadec   "0"
    :local remainder 0
    :local hexChars  "0123456789ABCDEF"
    :if ($dec > 0) do={:set hexadec ""}
    :while ( $dec > 0 ) do={
          :set remainder ($dec % 16)
          :set dec       (($dec-$remainder) / 16)
          :set hexadec   ([:pick $hexChars $remainder].$hexadec)
    } 
    :if ([:len $hexadec] = 1) do={:set hexadec "0$hexadec"}
    :return "0x$hexadec"
}
