# Source: https://forum.mikrotik.com/t/change-word-in-comment/163850/7
# Post author: @rextended
# Extracted from: code-block

:foreach item in=[/interface find where !dynamic and type="ether" and comment~"WORDBEFORE"] do={ :put [/interface get $item comment] }
