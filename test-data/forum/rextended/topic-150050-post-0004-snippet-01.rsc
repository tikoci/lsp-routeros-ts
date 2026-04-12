# Source: https://forum.mikrotik.com/t/changing-from-number-to-date/150050/4
# Post author: @rextended
# Extracted from: code-block

:global getMounth do={ :return [:pick [/system clock get date] 0 3] }
:global mon2num do={ :return ([:find "rexjanfebmaraprmayjunjulaugsepoctnovdec" $1 -1] / 3) }
:global num2NEXTmonth do={ :return [:pick "REXFEBMARAPRMAYJUNJULAUGSEPOCTNOVDECJAN" ($1*3) (($1*3)+3)] }
:log info [$num2NEXTmonth [$mon2num [$getMounth]]]
