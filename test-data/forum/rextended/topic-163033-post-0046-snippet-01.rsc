# Source: https://forum.mikrotik.com/t/iterate-over-all-elements-of-an-array-of-unknown-dimension/163033/46
# Post author: @rextended
# Extracted from: code-block

[[:parse ":global $[:pick $lpath ([:find $lpath "\$" -1] + 1) [:find $lpath "-" -1]]; :set ($lpath) \"new\""]]
