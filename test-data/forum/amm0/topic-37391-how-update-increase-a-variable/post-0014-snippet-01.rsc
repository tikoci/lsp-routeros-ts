# Source: https://forum.mikrotik.com/t/how-update-increase-a-variable/37391/14
# Topic: How update/increase a variable?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global mywgname "<myWG>"
 {
  :local wginterface [/interface/wireguard/find comment=$mywgname]
  :local wgcurport [/interface/wireguard/get $wginterface listen-port]
  /interface/wireguard/set $wginterface listen-port=($wgcurport + 2)
}
