# Source: https://forum.mikrotik.com/t/example-of-automating-vlan-creation-removal-inspecting-using-mkvlan-friends/181480/32
# Topic: 🧐 example of automating VLAN creation/removal/inspecting using $mkvlan & friends...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# to download:
/tool/fetch url=https://tikoci.github.io/scripts/lsbridge.rsc
     # to install as script
/system/script/add name=lsbridge source=[/file/get lsbridge.rsc contents]
     # to load script into CLI
/system/script/run lsbridge
     # to run just use:
$lsbridge
