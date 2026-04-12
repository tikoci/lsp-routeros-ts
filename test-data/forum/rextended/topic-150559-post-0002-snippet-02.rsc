# Source: https://forum.mikrotik.com/t/incomprehensible-behavior-of-netwatch-and-a-script-that-imitates-it/150559/2
# Post author: @rextended
# Extracted from: code-block

:local host 192.168.0.101

:global vdsdown
:global vdsstatus

# for test "warning unstable" set the count to 2
:local checkvds [/ping $host count=3]

:if ($checkvds = 0) do={
    :if ($vdsstatus != "offline") do={ /log error "Host $host change status from $vdsstatus to offline" }
    :set vdsstatus "offline"
    :set vdsdown true
}

:if (($checkvds > 0) && ($checkvds < 3)) do={
    :if ($vdsstatus != "unstable") do={ /log warning "Host $host change status from $vdsstatus to unstable" }
    :set vdsstatus "unstable"
    :set vdsdown false
}

:if ($checkvds = 3) do={
    :if ($vdsstatus != "online") do={ /log info "Host $host change status from $vdsstatus to online" }
    :set vdsstatus "online"
    :set vdsdown false
}
