# Source: https://forum.mikrotik.com/t/sorted-array-of-files/151870/10
# Post author: @rextended
# Extracted from: code-block

:global dobackup do={
    /system clock
    :local strDate [get date]; :local strTime [get time]
    :local arrMonths {jan="01";feb="02";mar="03";apr="04";may="05";jun="06";jul="07";aug="08";sep="09";oct="10";nov="11";dec="12"}
    :local intYear [:tonum [:pick $strDate 7 11]]; :local strMonth ($arrMonths->[:pick $strDate 0 3]); :local strDay [:pick $strDate 4 6]
    :local strHour [:pick $strTime 0 2]; :local strMinute [:pick $strTime 3 5]; :local strSecond [:pick $strTime 6 8]
    /system backup save dont-encrypt=yes name="$[/sys id get name]_$intYear-$strMonth-$strDay_$strHour$strMinute$strSecond"
}
