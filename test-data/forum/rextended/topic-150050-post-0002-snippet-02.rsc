# Source: https://forum.mikrotik.com/t/changing-from-number-to-date/150050/2
# Post author: @rextended
# Extracted from: code-block

:global mon2MON do={ :local strin "janfebmaraprmayjunjulaugsepoctnovdec"; :local strcomp "JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"; :return [:pick $strcomp [:find $strin $1 -1] ([:find $strin $1 -1]+3)] }
:put [$mon2MON "jul"]
