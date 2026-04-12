# Source: https://forum.mikrotik.com/t/convert-c-sample-to-knot-script/174770/4
# Topic: Convert C sample to KNOT script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global hex2ints do={
    :local hexdata $1
    :local intarray [:toarray ""]
    :for i from=0 to=[:len $hexdata] step=2 do={  
        :set ($intarray->($i / 2)) [:tonum "0x$[:pick $hexdata $i ($i +2) ]"]
    }
    :return $intarray
}
