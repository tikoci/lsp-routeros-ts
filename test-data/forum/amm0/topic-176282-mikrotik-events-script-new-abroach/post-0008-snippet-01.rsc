# Source: https://forum.mikrotik.com/t/mikrotik-events-script-new-abroach/176282/8
# Topic: mikrotik events script New abroach
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/address { :foreach i in=[find] do={ :put [get $i address] } 
    # or same using "fully-qualified" commands
:foreach i in=[/ip/address/find] do={ :put [/ip/address/get $i address] }
