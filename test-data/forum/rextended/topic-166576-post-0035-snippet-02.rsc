# Source: https://forum.mikrotik.com/t/warning-routeros-v7-10-will-break-all-scripts-based-on-system-clock-get-date-or-other-date-s/166576/35
# Post author: @rextended
# Extracted from: code-block

:return ({ "year"=[ :tonum  [ :pick $Date 7 11 ] ];
          "month"=($Months->[ :pick $Date 1  3 ]);
            "day"=[ :tonum  [ :pick $Date 4  6 ] ] });
