# Source: https://forum.mikrotik.com/t/example-of-automating-vlan-creation-removal-inspecting-using-mkvlan-friends/181480/17
# Topic: 🧐 example of automating VLAN creation/removal/inspecting using $mkvlan & friends...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:foreach testnum in=(1,60,128,256,257,512,513,4094,4095,1024*1024,1024*1024*1024,1024*1024*1024*1024) do={
    :local bytearray [:convert from=num to=byte-array $testnum]
    :put "$testnum got byte-array: $[:tostr $bytearray] ($[:len $bytearray] $[:typeof $bytearray])"
}
