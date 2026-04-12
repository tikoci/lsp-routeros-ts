# Source: https://forum.mikrotik.com/t/convert-c-sample-to-knot-script/174770/5
# Topic: Convert C sample to KNOT script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:global hex2ints
:local adverts [ /iot bluetooth scanners advertisements print as-value]
:foreach advert in=$adverts do={
     :local bytes [$hex2ints ($advert->"data")]
     :put "debug: $[:tostr $bytes]"
     :if (($bytes->0) != 13) do={:put "ERROR: 1st byte must be 13 or 0x0D"} 
     :if (($bytes->1) != 0xFF) do={:put "ERROR: 2nd byte must be FF"} 
     :local syncPressed [:tobool (($bytes->6) & 0x80)]
     :put "sync pressed $syncPressed"
}
}
