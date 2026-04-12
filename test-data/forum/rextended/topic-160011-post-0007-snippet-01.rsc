# Source: https://forum.mikrotik.com/t/script-fails-to-create-file/160011/7
# Post author: @rextended
# Extracted from: code-block

:global arrMonths {jan="01";feb="02";mar="03";apr="04";may="05";jun="06";jul="07";aug="08";sep="09";oct="10";nov="11";dec="12"}
:global addLogToFile do={
:local filename "$1"
:local fileext  ".txt"
/system clock
:local ndate  [get date]
:local ntime  [get time]
:local fdname "$[:pick $ndate 7 11]$($arrMonths->[:pick $ndate 0 3])$[:pick $ndate 4 6]$[:pick $ntime 0 2]$[:pick $ntime 3 5]"
:local isonow "$[:pick $ndate 7 11]-$($arrMonths->[:pick $ndate 0 3])-$[:pick $ndate 4 6] $ntime"
:local maxlen 4095
/file
:if ([:len [find where name="flash" and type="disk"]] = 1) do={:set filename "flash/$filename"}
:local wkfilename "$filename$fileext"
:if ([:len [find where name=$wkfilename]] = 0) do={print file="$wkfilename"; :delay 2s; set $wkfilename contents=""; :delay 1s}
:local bkfilename "$filename-$fdname$fileext"
:local filecon [get $wkfilename contents]
:local filelen [:len $filecon]
:local addthis "$isonow: $2\r\n"
:local addlen  [:len $addthis]
:if (($filelen + $addlen) > $maxlen) do={
    print file=$bkfilename
    :delay 2s
    set $bkfilename contents=$filecon
    :set filecon ""
    :set filelen 0
}
:set filecon  "$filecon$addthis"
set $wkfilename contents=$filecon
:delay 1s
}

{
:local interfaces "12.1_5g,12.1_ch1,12.2_ch1,12.3_ch6,12.4_ch11,12.5_ch11"
:local parentdir  "resziget" 

/file
:if ([:len [find where name="flash" and type="disk"]] = 1) do={:set parentdir "flash/$parentdir"}

/ip smb shares remove [find where name="temp"]
/ip smb shares add name="temp" directory=$parentdir

:foreach item in=[:toarray $interfaces] do={
    /ip smb shares remove [find where name="temp"]
    /ip smb shares add name=temp directory="$parentdir/$item"
    :local fname "$parentdir/$item/$item"
    :local logtx [:len [/caps-man registration-table find where interface=$item]]
#    :put "file name: \"$fname.txt\" - add this content: \"<DATE> <TIME>: $logtx\""
    [$addLogToFile $fname $logtx]
}

/ip smb shares remove [find where name="temp"]
}
