

/routing bgp evpn
add name=evpn1 vni=1010 export.route-targets=1010:1010 import.route-targets=1010:1010 instance=bgp1 disabled=no 
/interface vxlan 
    add name=vxlan1 vni=1010 bridge=([/interface/bridge/find]->0) bridge-pvid=10  
/ip address add address=2.2/24 interface=([/interface/bridge/find]->0)

:global someip 1.1.1.1
:global "set-dns" do={
    # global are bold & local are light, comments italics
    :global someip
    :local altip $1
    :if ([:typeof $altip] != "ip") do={:error "usage: \"\$fn <altip>\""}
    /ip dns set servers=($sometip,$altip)
}
$"set-dns" 1.1
:put "\E2\9A\99\EF\B8\8F\0A (utf-8 emoji)"



