# Source: https://forum.mikrotik.com/t/script-to-add-ip-to-list-based-on-log-help-needed/156344/4
# Post author: @rextended
# Extracted from: code-block

/log
:global okmsg "user admin logged in from "
:global failmsg "login failure for user admin from "
:global endmsg " via winbox"
:global listok "list_success_winbox_attempt"
:global listfail "list_failed_winbox_attempt"
:foreach rlog in=[find where message~"((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])"] do={
    :local rmess [get $rlog message]
    :if (($rmess~$okmsg) and ($rmess~$endmsg)) do={
         :local ipinside [:pick $rmess ([:find $rmess $okmsg -1] + [:len $okmsg]) [:find $rmess $endmsg -1]]
         /ip firewall address-list
         :if ([:len [find where list=$listok and address=$ipinside]] = 0) do={
             add list=$listok address=$ipinside
             :log warning "IP $ipinside added to $listok"
         }
    }
    :if (($rmess~$failmsg) and ($rmess~$endmsg)) do={
         :local ipinside [:pick $rmess ([:find $rmess $failmsg -1] + [:len $failmsg]) [:find $rmess $endmsg -1]]
         /ip firewall address-list
         :if ([:len [find where list=$listfail and address=$ipinside]] = 0) do={
             add list=$listfail address=$ipinside
             :log error "IP $ipinside added to $listfail"
         }
    }
}
