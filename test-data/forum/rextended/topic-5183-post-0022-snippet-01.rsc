# Source: https://forum.mikrotik.com/t/changing-the-mmm-dd-yyyy-date-format/5183/22
# Post author: @rextended
# Extracted from: code-block

:global currdatetimestrArr do={
    /system clock
    :local vdate [get date]
    :local vtime [get time]
    :local vgmt  [:tonum [get gmt-offset]]; :if ($vgmt > 0x7FFFFFFF) do={:set vgmt ($vgmt - 0x100000000)}
    :local prMntDays [:toarray "0,0,31,59,90,120,151,181,212,243,273,304,334"]
    :local daysOnMnt [:toarray "0,31,28,31,30,31,30,31,31,30,31,30,31"]
    :local LcaseMnts [:toarray "0,jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec"]
    :local PcaseMnts [:toarray "0,Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec"]
    :local UcaseMnts [:toarray "0,JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV,DEC"]
    :local LcaseWeekDays [:toarray "thu,fri,sat,sun,mon,tue,wed"]
    :local PcaseWeekDays [:toarray "Thu,Fri,Sat,Sun,Mon,Tue,Wed"]
    :local UcaseWeekDays [:toarray "THU,FRI,SAT,SUN,MON,TUE,WED"]
    :local NumbrWeekDays [:toarray "4,5,6,7,1,2,3"]
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
    :local Leap "No-Leap"
    :if ((($yyyy - 1968) % 4) = 0) do={:set Leap "Leap"; :set ($prMntDays->1) -1; :set ($prMntDays->2) 30; :set ($daysOnMnt->2) 29}
    :local mmm  ($LcaseMnts->$M)
    :local Mmm  ($PcaseMnts->$M)
    :local MMM  ($UcaseMnts->$M)
    :local MD   ($daysOnMnt->$M)
    :local dd   [:pick $vdate ($vdoff->4) ($vdoff->5)]
    :local d    [:tonum $dd] ; :local totd ((($yyyy - 1970) * 365) + (($yyyy - 1968) / 4) + ($prMntDays->$M) + ($d - 1))
    :local YD   (($prMntDays->$M) + $d)
    :local www  ($LcaseWeekDays->($totd % 7))
    :local Www  ($PcaseWeekDays->($totd % 7))
    :local WWW  ($UcaseWeekDays->($totd % 7))
    :local WD   ($NumbrWeekDays->($totd % 7))
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

    :local Arr [:toarray ""]
    :set  ($Arr->"yyyy") $yyyy
    :set  ($Arr->"MM"  ) $MM
    :set  ($Arr->"M"   ) $M
    :set  ($Arr->"MMM" ) $MMM
    :set  ($Arr->"Mmm" ) $Mmm
    :set  ($Arr->"mmm" ) $mmm
    :set  ($Arr->"MD"  ) $MD
    :set  ($Arr->"dd"  ) $dd
    :set  ($Arr->"d"   ) $d
    :set  ($Arr->"YD"  ) $YD
    :set  ($Arr->"WWW" ) $WWW
    :set  ($Arr->"Www" ) $Www
    :set  ($Arr->"www" ) $www
    :set  ($Arr->"WD"  ) $WD
    :set  ($Arr->"HH"  ) $HH
    :set  ($Arr->"H"   ) $H
    :set  ($Arr->"hh"  ) $hh
    :set  ($Arr->"h"   ) $h
    :set  ($Arr->"aa"  ) $aa
    :set  ($Arr->"a"   ) $a
    :set  ($Arr->"mm"  ) $mm
    :set  ($Arr->"m"   ) $m
    :set  ($Arr->"ss"  ) $ss
    :set  ($Arr->"s"   ) $s
    :set  ($Arr->"Z"   ) $Z
    :set  ($Arr->"Leap") $Leap
    :set  ($Arr->"Unix") $Unix

    :return $Arr
}

{
    :local x    [$currdatetimestrArr]
    :local Unix ($x->"Unix")
    :local HH   ($x->"HH")
    :local mm   ($x->"mm")
    :put "Current Unix time is: $Unix, so now are $HH:$mm"
}
