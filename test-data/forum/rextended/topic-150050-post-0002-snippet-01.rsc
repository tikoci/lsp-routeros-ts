# Source: https://forum.mikrotik.com/t/changing-from-number-to-date/150050/2
# Post author: @rextended
# Extracted from: code-block

:global num2month do={ :return [:pick "REXJANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC" ($1*3) (($1*3)+3)] }
:put [$num2month 7]
