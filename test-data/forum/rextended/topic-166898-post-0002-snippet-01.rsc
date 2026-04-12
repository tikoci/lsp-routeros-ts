# Source: https://forum.mikrotik.com/t/log-filter/166898/2
# Post author: @rextended
# Extracted from: code-block

[…]
:local lastTime [/system scheduler get [find name="$scheduleName"] comment]
[…]
	/system scheduler set [find name="$scheduleName"] comment=$currentTime
[…]
