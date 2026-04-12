# Source: https://forum.mikrotik.com/t/changing-the-mmm-dd-yyyy-date-format/5183/10
# Post author: @rextended
# Extracted from: code-block

:global simplercurrdatetimestr do={
    /system clock
    :local vdate [get date]
    :local vtime [get time]
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
    :local dd   [:pick $vdate ($vdoff->4) ($vdoff->5)]
    :local HH   [:pick $vtime 0  2]
    :local mm   [:pick $vtime 3  5]
    :local ss   [:pick $vtime 6  8]

    :return "$yyyy-$MM-$dd $HH:$mm:$ss"
}

:put [$simplercurrdatetimestr]
