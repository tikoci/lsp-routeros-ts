# Source: MikroTik forum — firewall address list updater from DNS
# https://forum.mikrotik.com/
# Used as test data for RouterOS LSP

:local domains {
  "example.com";
  "cdn.example.com";
  "api.example.com";
  "mail.example.com"
}

:local listName "allowed-hosts"

:foreach domain in=$domains do={
  :do {
    :local resolved [:resolve $domain]
    :local existing [/ip firewall address-list find where list=$listName address=$resolved]
    :if ([:len $existing] = 0) do={
      /ip firewall address-list add list=$listName address=$resolved timeout=1h comment=$domain
      :log info "Added $resolved ($domain) to $listName"
    } else={
      :log debug "$resolved ($domain) already in $listName"
    }
  } on-error={
    :log warning "DNS resolve failed for $domain"
  }
}
