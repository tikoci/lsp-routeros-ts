# Source: https://forum.mikrotik.com/t/i-did-it-script-to-compute-unix-time/68576/14
# Post author: @rextended
# Extracted from: code-block

/system clock
:global strDate [get date]
:global strTime [get time]
:global intGoff [:tonum [get gmt-offset]]
:if ($intGoff > 0x7FFFFFFF) do={:set intGoff ($intGoff - 0x100000000)}
:global arrMonths {jan="01";feb="02";mar="03";apr="04";may="05";jun="06";jul="07";aug="08";sep="09";oct="10";nov="11";dec="12"}
:global intYear   [:tonum [:pick $strDate 7 11]]
:global strMonth  ($arrMonths->[:pick $strDate 0 3])
:global strDay    [:pick $strDate 4 6]
:global strHour   [:pick $strTime 0 2]
:global strMinute [:pick $strTime 3 5]
:global strSecond [:pick $strTime 6 8]
:global strOffsig "+"
:global strGoff   $intGoff
:if ($intGoff < 0) do={:set strOffsig "-"; :set strGoff ($intGoff * -1)}
:global strHoff  [:pick [:totime $strGoff] 0 2]
:global strMoff  [:pick [:totime $strGoff] 3 5]
:global strISOdate "$intYear-$strMonth-$strDay\54$strHour:$strMinute:$strSecond$strOffsig$strHoff:$strMoff"
:put "$strDate $strTime $strOffsig$intGoff converted to ISO format is $strISOdate"
