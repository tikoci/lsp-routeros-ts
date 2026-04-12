# Source: https://forum.mikrotik.com/t/importing-ip-list-from-file/143071/18
# Post author: @rextended
# Extracted from: code-block

:global testip [:pick $teststr ([:find $teststr "address=" 29] + 8) [:find $teststr " list=" 29]]
:if ($testip~"((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\/(3[0-2]|[0-2]\?[0-9])") do={ \
    :put "$testip is a IP-prefix"
} else={:put "$testip is NOT a IP-prefix"}
