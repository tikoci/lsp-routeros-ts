# Source: https://forum.mikrotik.com/t/how-to-completely-disable-unused-routing-protocols/168385/2
# Topic: How to completely disable unused routing protocols
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system/device-mode/update <tab> 
activation-timeout     email                l2tp          smb              
append                 fetch                mode          sniffer          
as-value               flagged              once          socks            
bandwidth-test         flagging-enabled     pptp          traffic-gen      
container              hotspot              proxy         without-paging   
do                     interval             romon         zerotier         
duration               ipsec                scheduler     file
