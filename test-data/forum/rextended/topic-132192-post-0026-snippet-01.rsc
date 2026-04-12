# Source: https://forum.mikrotik.com/t/can-a-script-be-created-if-a-wrong-login-name-is-used/132192/26
# Post author: @rextended
# Extracted from: code-block

:if ([:len [/user find where name=$userinside]] = 0) do={
             /ip firewall address-list
             :if ([:len [find where list=$listfail and address=$ipinside]] = 0) do={
                 add list=$listfail address=$ipinside comment="$rmess"
             }
         }
