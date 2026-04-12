# Source: https://forum.mikrotik.com/t/convert-uptime-to-date-and-time/157724/12
# Post author: @rextended
# Extracted from: code-block

:global currdatetimestr do={
    /system clock
    :local vdate [get date]
    :local vtime [get time]
    :local vgmt  [:tonum [get gmt-offset]]; :if ($vgmt > 0x7FFFFFFF) do={:set vgmt ($vgmt - 0x100000000)}
    :local prMntDays [:toarray "0,0,31,59,90,120,151,181,212,243,273,304,334"]
    :local LcaseMnts [:toarray "0,jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec"]
    :local PcaseMnts [:toarray "0,Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec"]
    :local UcaseMnts [:toarray "0,JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV,DEC"]
    :local LcaseWeekDays [:toarray "thu,fri,sat,sun,mon,tue,wed"]
    :local PcaseWeekDays [:toarray "Thu,Fri,Sat,Sun,Mon,Tue,Wed"]
    :local UcaseWeekDays [:toarray "THU,FRI,SAT,SUN,MON,TUE,WED"]
    :local Fzerofill do={:return [:pick (100 + $1) 1 3]}
    :local gmtSg "+"; :if ($vgmt < 0) do={:set gmtSg "-"; :set vgmt ($vgmt * -1)}
    :local gmtHr [:pick [:totime $vgmt] 0 2]
    :local gmtMn [:pick [:totime $vgmt] 3 5]
    :local vdoff [:toarray "0,4,5,7,8,10"]
    :local MM    [:pick $vdate ($vdoff->2) ($vdoff->3)]
    :local M     [:tonum $MM]
    :if ($vdate ~ ".../../....") do={
        :set vdoff [:toarray "7,11,1,3,4,6"]
        :set M     ([:find "xxanebarprayunulugepctovecANEBARPRAYUNULUGEPCTOVEC" [:pick $vdate ($vdoff->2) ($vdoff->3)] -1] / 2)
        :if ($M>12) do={:set M ($M - 12)}
        :set MM    [:pick (100 + $M) 1 3]
    }
    :local yyyy [:pick $vdate ($vdoff->0) ($vdoff->1)]
    :local Leap "No-Leap" ; :if ((($yyyy - 1968) % 4) = 0) do={:set Leap "Leap"; :set ($prMntDays->1) -1; :set ($prMntDays->2) 30}
    :local mmm  ($LcaseMnts->$M)
    :local Mmm  ($PcaseMnts->$M)
    :local MMM  ($UcaseMnts->$M)
    :local dd   [:pick $vdate ($vdoff->4) ($vdoff->5)]
    :local d    [:tonum $dd] ; :local totd ((($yyyy - 1970) * 365) + (($yyyy - 1968) / 4) + ($prMntDays->$M) + ($d - 1))
    :local www  ($LcaseWeekDays->($totd % 7))
    :local Www  ($PcaseWeekDays->($totd % 7))
    :local WWW  ($UcaseWeekDays->($totd % 7))
    :local HH   [:pick $vtime 0  2]
    :local H    [:tonum $HH]
    :local hh   ([:tonum $HH] % 12); :if ($hh = 0) do={:set hh 12}; :set hh [$Fzerofill $hh]
    :local h    [:tonum $hh]
    :local a    "A"; :if ([:tonum $HH] > 11) do={:set a "P"}
    :local aa   "$a\4D"
    :local mm   [:pick $vtime 3  5]
    :local m    [:tonum $mm]
    :local ss   [:pick $vtime 6  8]
    :local s    [:tonum $ss]
    :local Z    "$gmtSg$gmtHr:$gmtMn"
    :local Unix (((((($totd * 24) + $H) * 60) + $m) * 60) + $s - $vgmt)

#    :return "$yyyy-$MM-$dd\54$HH:$mm:$ss$Z $Www $Leap $Unix"
    :return $Unix
}

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
#    :return "$yearStart/$[$Fzerofill $mnthStart]/$[$Fzerofill $dayStart] $timeStart"
    :return "$[$Fzerofill $dayStart]/$[$Fzerofill $mnthStart]/$yearStart $timeStart"
}

:global timetoseconds do={
    :local inTime $1
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

:put "RouterBOARD is started $[$unixtodatetime ([$currdatetimestr] - [$timetoseconds [/system resource get uptime]])]"
