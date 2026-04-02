# Source: MikroTik forum — representative DHCP lease script pattern
# https://forum.mikrotik.com/
# Used as test data for RouterOS LSP

:local leaseActMAC $"lease-hostname"
:local leaseActIP $"lease-address"
:local leaseServerName $"lease-server"

:if ($leaseBound = 1) do={
  :log info "DHCP lease bound: $leaseActMAC got $leaseActIP from $leaseServerName"
  /ip dns static {
    :local entry [find where name="$leaseActMAC.lan"]
    :if ([:len $entry] > 0) do={
      set $entry address=$leaseActIP
    } else={
      add name="$leaseActMAC.lan" address=$leaseActIP ttl=1d
    }
  }
} else={
  :log info "DHCP lease released: $leaseActMAC released $leaseActIP"
  /ip dns static remove [find where name="$leaseActMAC.lan"]
}
