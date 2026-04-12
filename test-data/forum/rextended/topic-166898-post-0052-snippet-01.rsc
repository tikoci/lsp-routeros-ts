# Source: https://forum.mikrotik.com/t/log-filter/166898/52
# Post author: @rextended
# Extracted from: code-block

:local normalTime (($months->$dateM)."/");
:if ($dateD < 10) do={ :set $normalTime ($normalTime."0".[:tostr $dateD]."/"); } else={ :set $normalTime ($normalTime.[:tostr $dateD]."/"); }
:set $normalTime ($normalTime.[:tostr $dateY]." ");   
:if ($timeH < 10) do={ :set $normalTime ($normalTime."0".[:tostr $timeH].":"); } else={ :set $normalTime ($normalTime.[:tostr $timeH].":"); }
:if ($timeM < 10) do={ :set $normalTime ($normalTime."0".[:tostr $timeM].":"); } else={ :set $normalTime ($normalTime.[:tostr $timeM].":"); }
:if ($timeS < 10) do={ :set $normalTime ($normalTime."0".[:tostr $timeS]); }     else={ :set $normalTime ($normalTime.[:tostr $timeS]); }
