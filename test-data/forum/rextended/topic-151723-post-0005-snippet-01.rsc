# Source: https://forum.mikrotik.com/t/fetch-capable-of-following-redirects/151723/5
# Post author: @rextended
# Extracted from: code-block

# wrong coding
:do {/interface bridge add name=loopback; } on-error={:put "loopback exists"}
# translating: create loopback, if you got an error because already exist, ignore it
# on short: create it, hoping not already exist

# right coding
/interface bridge
:if ([:len [:find where name="loopback"]] = 0) do={add name=loopback}
# translating: if the result of the count of interface named loopback are zero, create the interface
# on short: if not exist, create it
