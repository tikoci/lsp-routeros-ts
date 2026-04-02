# Source: MikroTik forum — failover script with recursive routing pattern
# https://forum.mikrotik.com/
# Used as test data for RouterOS LSP

:local pingTarget "8.8.8.8"
:local wan1Gateway "192.168.1.1"
:local wan2Gateway "192.168.2.1"

:local wan1Status [/ping $pingTarget count=3 interface=ether1]
:local wan2Status [/ping $pingTarget count=3 interface=ether2]

:if ($wan1Status = 0) do={
  :log warning "WAN1 is DOWN — switching to WAN2"
  /ip route set [find comment="WAN1"] disabled=yes
  /ip route set [find comment="WAN2"] disabled=no
} else={
  :if ($wan2Status = 0) do={
    :log warning "WAN2 is DOWN — switching to WAN1"
    /ip route set [find comment="WAN2"] disabled=yes
    /ip route set [find comment="WAN1"] disabled=no
  } else={
    :log info "Both WANs are UP"
    /ip route set [find comment="WAN1"] disabled=no
    /ip route set [find comment="WAN2"] disabled=no
  }
}
