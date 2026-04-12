# Source: https://forum.mikrotik.com/t/i-did-it-script-to-compute-unix-time/68576/14
# Post author: @rextended
# Extracted from: code-block

:global arrPreMonDays {"01"=0;"02"=31;"03"=59;"04"=90;"05"=120;"06"=151;"07"=181;"08"=212;"09"=243;"10"=273;"11"=304;"12"=334}
# 1970-01-01 is a Thursday
:global arrWeekDays   {"Thu";"Fri";"Sat";"Sun";"Mon";"Tue";"Wed"}
# first bixestile year immediately before 1970 is 1968
:global numTotalDays  (($intYear - 1968) / 4)
:global bolLeapYear   false
:if ((($intYear - 1968) % 4) = 0) do={:set bolLeapYear true; :set ($arrPreMonDays->"01") -1; :set ($arrPreMonDays->"02") 30}
:set numTotalDays  ($numTotalDays + (($intYear - 1970) * 365))
:set numTotalDays  ($numTotalDays + ($arrPreMonDays->$strMonth))
:set numTotalDays  ($numTotalDays + ([:tonum $strDay] - 1))
:global strWeekDay ($arrWeekDays->($numTotalDays % 7))
:global numTotHours   (($numTotalDays * 24) + [:tonum $strHour])
:global numTotMinutes (($numTotHours * 60) + [:tonum $strMinute])
:global numTotSeconds (($numTotMinutes * 60) + [:tonum $strSecond] - $intGoff)
:put "For $strISOdate UNIX time is $numTotSeconds the current year is a lap year:$bolLeapYear and the Week Day is $strWeekDay"
