# Source: https://forum.mikrotik.com/t/changing-from-number-to-date/150050/2
# Post author: @rextended
# Extracted from: code-block

:global mon2num do={ :return ([:find "rexjanfebmaraprmayjunjulaugsepoctnovdec" $1 -1] / 3) }
:put [$mon2num "jul"]
