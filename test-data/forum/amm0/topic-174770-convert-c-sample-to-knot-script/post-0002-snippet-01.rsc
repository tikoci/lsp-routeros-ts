# Source: https://forum.mikrotik.com/t/convert-c-sample-to-knot-script/174770/2
# Topic: Convert C sample to KNOT script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/iot bluetooth scanners advertisements {  
  :local adids [find]
  :foreach adid in=$adids do={
     :local pkt [get $adid]
    :local pktdata ($pkt->"data")
    :if ([:len $pktdata]!=18 || [:pick $pktdata 1 2]="\FF") do={:error "bad packet: got $pktdata with length $[:len $pktdata]"}
    :local acceloY [:pick 12 13]
    :local acceloX [:pick 13 14]
    :local temp ([:tonum [:pick 6 7]] & 0x7F)
    :put "$adid has X: $acceloX Y: $acceloY   temp: $temp"
  }
}
