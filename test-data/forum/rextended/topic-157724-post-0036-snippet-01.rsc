# Source: https://forum.mikrotik.com/t/convert-uptime-to-date-and-time/157724/36
# Post author: @rextended
# Extracted from: code-block

:global unixtodatetime do={
    :local ux [:tonum $1]
    :local Fzerofill do={:return [:pick (100 + $1) 1 3]}
    :local prMntDays [:toarray "0,0,31,59,90,120,151,181,212,243,273,304,334"]
    :local vgmt      [:tonum [/system clock get gmt-offset]]; :if ($vgmt > 0x7FFFFFFF) do={:set vgmt ($vgmt - 0x100000000)}
    :if ($vgmt < 0) do={:set vgmt ($vgmt * -1)}
    :local tzepoch   ($ux + $vgmt)
    :if ($tzepoch < 0) do={:set tzepoch 0} ; # unsupported negative unix epoch
    :local yearStart (1970 + ($tzepoch / 31536000))
    :local tmpbissex (($yearStart - 1968) / 4) ; :if ((($yearStart - 1968) % 4) = 0) do={:set ($prMntDays->1) -1 ; :set ($prMntDays->2) 30}
    :local tmpsec    ($tzepoch % 31536000)
    :local tmpdays   (($tmpsec / 86400) - $tmpbissex)
    :if (($tmpsec < (86400 * $tmpbissex)) and ((($yearStart - 1968) % 4) = 0)) do={
        :set tmpbissex ($tmpbissex - 1) ; :set ($prMntDays->1) 0 ; :set ($prMntDays->2) 31 ; :set tmpdays  ($tmpdays + 1)
    }
    :if ($tmpsec < (86400 * $tmpbissex)) do={:set yearStart ($yearStart - 1) ; :set tmpdays   ($tmpdays + 365)}
    :local mnthStart 12 ; :while (($prMntDays->$mnthStart) > $tmpdays) do={:set mnthStart ($mnthStart - 1)}
    :local dayStart  [$Fzerofill (($tmpdays + 1) - ($prMntDays->$mnthStart))]
    :local timeStart (00:00:00 + [:totime ($tmpsec % 86400)])
    :return "$yearStart/$[$Fzerofill $mnthStart]/$[$Fzerofill $dayStart] $timeStart"
}
