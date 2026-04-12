# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/18
# Post author: @rextended
# Extracted from: code-block

:global binQW2hex do={
    :local bin $1
    :local dec  0
    :local mol  1
    :local lgt [:len $bin]
    :if (!($bin~"^[0-1]{$lgt}\$")) do={:return "0x00"}
    :for pos from=1 to=$lgt do={
        :local temp [:tonum [:pick $bin ($lgt - $pos) ($lgt - $pos + 1)]]
        :set dec ($dec + ($temp * $mol))
        :set mol ($mol * 2)
    }
    :local firstchar ""
    :if ($dec < 0) do={
        :local chk (($dec & 0x7000000000000000) >> 60)
        :set firstchar [:pick "89ABCDEF" $chk ($chk + 1)]
        :set dec ($dec & 0x0FFFFFFFFFFFFFFF)
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
    :if ($firstchar != "") do={
        :set hexadec "00000000000000$hexadec"
        :set hexadec "$firstchar$[:pick $hexadec ([:len $hexadec] - 15) [:len $hexadec]]"
    }
    :return "0x$hexadec"
}
