# Source: https://forum.mikrotik.com/t/find-addresses-with-same-octets/168376/6
# Topic: find addresses with same octets
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local listname octettest3
/ip/firewall/address-list
:foreach i in={192.168.88.3;192.168.88.67;192.168.88.12;192.168.0.11;192.168.67.5;192.168.88.34} do={add list=$listname address=$i}  
:foreach a in=[find (address in 192.168.88.0/24) and (list=$listname)] do={:put [get $a address]}
remove [find list=$listname]
}
