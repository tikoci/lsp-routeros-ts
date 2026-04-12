# Source: https://forum.mikrotik.com/t/convert-uptime-to-date-and-time/157724/37
# Post author: @rextended
# Extracted from: code-block

:global timetoseconds do={
    :local inTime [:totime $1]
    :local wPos   [:find $inTime "w" -1]
    :local dPos   [:find $inTime "d" -1]
    :local itLen  [:find $inTime "." -1] ; :if ([:typeof $itLen] = "nil") do={:set itLen [:len $inTime]}
    :local itSec  [:pick $inTime ($itLen - 2) $itLen]
    :local itMin  [:pick $inTime ($itLen - 5) ($itLen - 3)]
    :local itHou  [:pick $inTime ($itLen - 8) ($itLen - 6)]
    :local itDay  0
    :local itWee  0
    :if (([:typeof $wPos] = "nil") and ([:typeof $dPos] = "num")) do={:set itDay [:pick $inTime 0 $dPos] }
    :if (([:typeof $wPos] = "num") and ([:typeof $dPos] = "num")) do={:set itDay [:pick $inTime ($wPos + 1) $dPos] }
    :if  ([:typeof $wPos] = "num")                                do={:set itWee [:pick $inTime 0 $wPos] }
    :local totitSec ($itSec + (60 * $itMin) + (3600 * $itHou) + (86400 * $itDay) + (604800 * $itWee))
    :return $totitSec
}
