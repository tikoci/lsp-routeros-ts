# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/18
# Post author: @rextended
# Extracted from: code-block

:global binQW2dec do={
    :local bin $1
    :local dec  0
    :local mol  1
    :local lgt [:len $bin]
    :if (!($bin~"^[0-1]{$lgt}\$")) do={:return 0}
    :for pos from=1 to=$lgt do={
        :local temp [:tonum [:pick $bin ($lgt - $pos) ($lgt - $pos + 1)]]
        :set dec ($dec + ($temp * $mol))
        :set mol ($mol * 2)
    }
    :return $dec
}
