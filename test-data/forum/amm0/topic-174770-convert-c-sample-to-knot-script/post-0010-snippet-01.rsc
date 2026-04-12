# Source: https://forum.mikrotik.com/t/convert-c-sample-to-knot-script/174770/10
# Topic: Convert C sample to KNOT script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# Main function to decode Bluetooth advertisement data
/iot bluetooth scanners advertisements {  
    :local adids [find]
    :foreach adid in=$adids do={
       :local pkt [get $adid]
       :local pktdata ($pkt->"data")
       :if ([:len $pktdata]!=36 || [:pick $pktdata 1 2]="\FF") do={:error "bad packet: got $pktdata with length $[:len $pktdata]"}

      # Extract fields from advertisement data
      :local batteryVoltage [:tonum "0x$[:pick $pktdata 10 (10 + 2) ]"] 
      :local temperature [:tonum "0x$[:pick $pktdata 12 (12 + 2) ]"] 
      :local tankLevel [:tonum "0x$[:pick $pktdata 14 (10 + 4) ]"] 

       :put "payload:$pktdata"
       :put "batteryVoltage: $batteryVoltage"
       :put "temperature: $temperature"
       :put "tankLevel: $tankLevel"
     }
}
