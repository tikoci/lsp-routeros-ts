# Source: https://forum.mikrotik.com/t/example-of-automating-vlan-creation-removal-inspecting-using-mkvlan-friends/181480/13
# Topic: 🧐 example of automating VLAN creation/removal/inspecting using $mkvlan & friends...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    :put "== use :convert to make a byte-array so we can get at the IP parts"
    :local vbytes [:convert from=num to=byte-array 60]
     :local lowbits ($vbytes->0)
    :local highbits ($vbytes->1)
    :local ipprefix "0.0.0"
    :put "\t... got $[:tostr $vbytes]"

    :put "== verify :convert is working as expected"
    :put  "\tHIGH: $[:typeof ($vbytes->1)] $[:len ($vbytes->1)] $($vbytes->1)"
    :put  "\tLOW: $[:typeof ($vbytes->0)] $[:len ($vbytes->0)] $($vbytes->0)"
    :put "\t** HIGH should be 'nothing' - if it something, thats a bug" 

    :put "== replicate SAME code in pvid2array"  
    :if ([:typeof $highbits] = "nothing") do={
        :set ipprefix "192.168.$lowbits"
    } else={
        :set ipprefix "172.$($lowbits + 15).$highbits" 
    }
    :put "\t... which gets a prefix of: $ipprefix" 

    :put "== use DIFFERENT code in pvid2array to check instead for !num"  
    :if ([:typeof $highbits] != "num") do={
        :set ipprefix "192.168.$lowbits"
    } else={
        :set ipprefix "172.$($lowbits + 15).$highbits" 
    }
    :put "\t... which gets a prefix of: $ipprefix" 

}
