# Source: https://forum.mikrotik.com/t/i-did-it-script-to-compute-unix-time/68576/24
# Post author: @rextended
# Extracted from: code-block

:global datetime2epoch do={
    :local dtime [:tostr $1]
    /system clock
    :local cyear [get date] ; :if ($cyear ~ "....-..-..") do={:set cyear [:pick $cyear 0 4]} else={:set cyear [:pick $cyear 7 11]}
    :if (([:len $dtime] = 10) or ([:len $dtime] = 11)) do={:set dtime "$dtime 00:00:00"}
    :if ([:len $dtime] = 15) do={:set dtime "$[:pick $dtime 0 6]/$cyear $[:pick $dtime 7 15]"}
    :if ([:len $dtime] = 14) do={:set dtime "$cyear-$[:pick $dtime 0 5] $[:pick $dtime 6 14]"}
    :if ([:len $dtime] =  8) do={:set dtime "$[get date] $dtime"}
    :if ([:tostr $1] = "") do={:set dtime ("$[get date] $[get time]")}
    :local vdate [:pick $dtime 0 [:find $dtime " " -1]]
    :local vtime [:pick $dtime ([:find $dtime " " -1] + 1) [:len $dtime]]
    :local vgmt  [get gmt-offset]; :if ($vgmt > 0x7FFFFFFF) do={:set vgmt ($vgmt - 0x100000000)}
    :if ($vgmt < 0) do={:set vgmt ($vgmt * -1)}
    :local arrm  [:toarray "0,0,31,59,90,120,151,181,212,243,273,304,334"]
    :local vdoff [:toarray "0,4,5,7,8,10"]
    :local MM    [:pick $vdate ($vdoff->2) ($vdoff->3)]
    :local M     [:tonum $MM]
    :if ($vdate ~ ".../../....") do={
        :set vdoff [:toarray "7,11,1,3,4,6"]
        :set M     ([:find "xxanebarprayunulugepctovecANEBARPRAYUNULUGEPCTOVEC" [:pick $vdate ($vdoff->2) ($vdoff->3)] -1] / 2)
        :if ($M>12) do={:set M ($M - 12)}
    }
    :local yyyy  [:pick $vdate ($vdoff->0) ($vdoff->1)] ; :if ((($yyyy - 1968) % 4) = 0) do={:set ($arrm->1) -1; :set ($arrm->2) 30}
    :local totd  ((($yyyy - 1970) * 365) + (($yyyy - 1968) / 4) + ($arrm->$M) + ([:pick $vdate ($vdoff->4) ($vdoff->5)] - 1))
    :return      (((((($totd * 24) + [:pick $vtime 0 2]) * 60) + [:pick $vtime 3 5]) * 60) + [:pick $vtime 6 8] - $vgmt)
}
