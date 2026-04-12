# Source: https://forum.mikrotik.com/t/wishes-for-7-17-beta/178918/8
# Topic: Wishes for 7.17 beta
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system/logging/action/add name=custom-syslog script={
   :local fac 16
   :local sev 6 
   :if ($topics~"debug") do={:set sev 7}
   # ... 
   # & need some method to actually send a syslog 
   /log syslog severity=$sev facility=$fac timestamp=yes msg="..."
}
