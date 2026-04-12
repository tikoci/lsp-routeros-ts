# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/18
# Post author: @rextended
# Extracted from: code-block

:global bin2dec do={
    :local bin $1
    :local dec  0
    :local mol  1
    :if (!($bin~"^[0-1]{8}\$")) do={:return 0}
    :for pos from=1 to=8 do={
        :local temp [:tonum [:pick $bin (8 - $pos) (8 - $pos + 1)]]
        :set dec ($dec + ($temp * $mol))
        :set mol ($mol * 2)
    }
    :return $dec
}
