# Source: https://forum.mikrotik.com/t/can-a-script-be-created-if-a-wrong-login-name-is-used/132192/29
# Post author: @rextended
# Extracted from: code-block

/log
:global maxattampt 3
:global errorArray [:toarray ""]
:global failmsg  "login failure for user "
:global frommsg  " from "
:global viamsg   " via "
:global listfail "list_failed_attempt"
:foreach rlog in=[find where message~"((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])"] do={
    :local rmess [get $rlog message]
    :if (($rmess~$failmsg) and ($rmess~$frommsg) and ($rmess~$viamsg)) do={
         :local userinside [:pick $rmess ([:find $rmess $failmsg -1] + [:len $failmsg]) [:find $rmess $frommsg -1]]
         :local ipinside [:pick $rmess ([:find $rmess $frommsg -1] + [:len $frommsg]) [:find $rmess $viamsg -1]]
         :local intinside [:pick $rmess ([:find $rmess $viamsg -1] + [:len $viamsg]) [:len $rmess]]
         :if ([:typeof (($errorArray)->$ipinside)] = "nothing") do={
             :set (($errorArray)->$ipinside) 1
         } else={
             :set (($errorArray)->$ipinside) ((($errorArray)->$ipinside) + 1)
         }
         :if ((($errorArray)->$ipinside) > ($maxattampt - 1)) do={
             /ip firewall address-list
             :if ([:len [find where list=$listfail and address=$ipinside]] = 0) do={
                 add list=$listfail address=$ipinside comment="$rmess"
             }
         }
    }
}
