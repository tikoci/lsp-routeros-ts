# Source: https://forum.mikrotik.com/t/would-like-new-data-appended-to-file/262655/67
# Topic: Would like new data appended to file
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system/ups/monitor 0 do={:put [:typeof $<<tab>>    
"battery-charge"      "line-voltage"      "on-battery"         "replace-battery"     "smart-boost"      
"battery-voltage"     load                "on-line"            "rtc-running"         "smart-trim"       
frequency             "low-battery"       "output-voltage"     "runtime-left"        temperature        
"hid-self-test"       "offline-after"     overload             "self-test"           "transfer-cause"
