# Source: https://forum.mikrotik.com/t/example-of-automating-vlan-creation-removal-inspecting-using-mkvlan-friends/181480/24
# Topic: 🧐 example of automating VLAN creation/removal/inspecting using $mkvlan & friends...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[eddie@ccr1009] > :foreach testnum in=(1,60,128,256,257,512,513,4094,4095,1024*1024,1024*1024*1024,1024*1024*1024*1024) do={
{...     :local bytearray [:convert from=num to=byte-array $testnum]
syntax error (line 2 column 37)
