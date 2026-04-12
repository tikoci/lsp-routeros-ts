# Source: https://forum.mikrotik.com/t/importing-ip-list-from-file/143071/29
# Post author: @rextended
# Extracted from: code-block

:global teststr ("# Generated 2021-08-10 12:01:25.213173\n2.84.0.0/14\n5.54.0.0/15\n5.144.192.0/18\n5.172.192.0/20\n\
    5.203.0.0/32\n31.14.168.0/0\n31.14.208.0/00\n")

:global addlist "test"
:global keep true
# head and tail for ip-prefix are \n
:global head "\n"
:global tail "\n"

:global regexipwithsubnet "((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\/(3[0-2]|[0-2]\?[0-9])"
:global lenght [:len $teststr]
:global offset [:len $head]
:global actualhead -1
:global actualtail -1
:global testip ""

/ip firewall address-list

:if (!($keep)) do={ remove [find where list=$addlist] }

:while ([:typeof $actualtail] != "nil") do={
    :set actualhead ([:find $teststr $head $actualtail] + $offset)
    :set actualtail [:find $teststr $tail $actualhead]
    :if ([:typeof $actualtail] != "nil") do={
        :set testip [:pick $teststr $actualhead $actualtail]
        :if ($testip ~ $regexipwithsubnet) do={
            :if ($testip ~ "\\/0(0|\$)") do={
                :log warning "Invalid IP-prefix >$testip<"
            } else={
                :if ($testip ~ "\\/32") do={ :set testip [:pick $testip 0 [:find $testip "/32" -1]] }
                :if ([:len [find where list=$addlist and address=$testip]] = 0) do={ add list=$addlist address=$testip }
            }
        }
    }
}
