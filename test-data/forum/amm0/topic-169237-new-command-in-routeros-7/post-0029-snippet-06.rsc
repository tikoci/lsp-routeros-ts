# Source: https://forum.mikrotik.com/t/new-command-in-routeros-7/169237/29
# Topic: New command in RouterOs 7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/console/inspect request=self path=ip

Columns: TYPE, NAME, NODE-TYPE
TYPE   NAME          NODE-TYPE
self   ip            path     
child  address       dir      
child  arp           dir      
child  cloud         dir      
child  dhcp-client   dir      
child  dhcp-relay    dir      
child  dhcp-server   dir      
child  dns           dir      
child  firewall      dir      
child  hotspot       dir      
child  ipsec         dir      
child  kid-control   dir      
child  neighbor      dir      
child  packing       dir      
child  pool          dir      
child  proxy         dir      
child  route         dir      
child  service       dir      
child  settings      dir      
child  smb           dir      
child  socks         dir      
child  ssh           dir      
child  tftp          dir      
child  traffic-flow  dir      
child  upnp          dir      
child  vrf           dir      
child  export        cmd
