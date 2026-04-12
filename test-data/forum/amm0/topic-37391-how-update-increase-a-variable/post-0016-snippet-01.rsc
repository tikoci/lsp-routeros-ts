# Source: https://forum.mikrotik.com/t/how-update-increase-a-variable/37391/16
# Topic: How update/increase a variable?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global mywgname "<myWG>"
 {
  :local wginterface [/interface/wireguard/find comment=$mywgname]
  :local wgcurport [/interface/wireguard/get $wginterface listen-port]
  /log info "about to update WG for $mywgname with id $wginterface using port $wgcurport"
  /interface/wireguard/set $wginterface listen-port=($wgcurport + 2)
  :delay 1s
  :set wgcurport [/interface/wireguard/get $wginterface listen-port]
  /log info "updated WG for $mywgname to use NEW port: $wgcurport"
}
