# Source: https://forum.mikrotik.com/t/importing-ip-list-from-file/143071/52
# Post author: @rextended
# Extracted from: code-block

:global loglist [/system logging find where disabled=no topics~"((^|,)info|(^|,)system)"]
/system logging disable $loglist

# ... all the script ...

/system logging enable $loglist
