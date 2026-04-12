# Source: https://forum.mikrotik.com/t/importing-ip-list-from-file/143071/18
# Post author: @rextended
# Extracted from: code-block

# test string
:global teststr ":do { add address=2.84.0.0/14 list=GR } on-error={}\r\n:do { add address=5.54.0.0/15 list=GR } on-error={}"

# remove head and tail, used + 8 because is the character lenght of "address="
# instead of a fixed value can be set also, for example, with [:len $rightstrdelimiter] on script
# notice the needed space before list
:global testip [:pick $teststr ([:find $teststr "address=" -1] + 8) [:find $teststr " list=" -1]]

# now I chech against regexp if is valid IP-prefix
:if ($testip~"((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\/(3[0-2]|[0-2]\?[0-9])") do={ \
    :put "$testip is a IP-prefix"
} else={:put "$testip is NOT a IP-prefix"}
