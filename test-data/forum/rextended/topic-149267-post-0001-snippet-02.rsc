# Source: https://forum.mikrotik.com/t/random-number-between-0-and-99-or-string-between-00-and-99/149267/1
# Post author: @rextended
# Extracted from: code-block

:global randomstr do={
    /system resource irq
    :local tmpsum 0
    :foreach i in=[find] do={:set tmpsum ($tmpsum + [get $i count])}
    :set   tmpsum [:tostr $tmpsum]
    :local lentmp [:len   $tmpsum]
    :return [:pick $tmpsum ($lentmp - 2) $lentmp]
}
