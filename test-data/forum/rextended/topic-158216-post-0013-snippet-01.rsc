# Source: https://forum.mikrotik.com/t/sms-timestamp-system-date-and-case-sensitive/158216/13
# Post author: @rextended
# Extracted from: code-block

:global engdate2int do={
    :local input    [:tostr $1]
    :local arrMonths {an=1;eb=2;ar=3;pr=4;ay=5;un=6;ul=7;ug=8;ep=9;ct=10;ov=11;ec=12}
    :local intYear  ([:tonum [:pick $input 7 11]] * 10000)
    :local intMonth ([:tonum ($arrMonths->[:pick $input 1 3])] * 100)
    :local intDay   [:tonum [:pick $input 4 6]]

    :return ($intYear + $intMonth + $intDay)
}

{
:local timestamp "May/23/2022 17:42:43 GMT -0"
:local today [/sys clock get date]

:local intstamp [$engdate2int $timestamp]
:local inttoday [$engdate2int $today]

:put "today = $inttoday ; timestamp = $intstamp"

:if ( $inttoday      = $intstamp) do={ :put "SMS Sent today" }
:if (($inttoday - 1) = $intstamp) do={ :put "SMS Sent yesterday" }
}
