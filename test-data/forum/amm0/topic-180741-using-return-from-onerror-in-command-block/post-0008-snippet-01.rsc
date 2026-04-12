# Source: https://forum.mikrotik.com/t/using-return-from-onerror-in-command-block/180741/8
# Topic: Using :return from :onerror in= command block
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# corrent per docs, but still weird:
:put [:onerror e in={:return true} do={:return 1.1}]
# false

# wrong! the return value should be true, if docs are right…
:put [:onerror e in={:error "throw"} do={:return 1.1}]
# 1.0.0.1

# correct per docs, since do={} is run
:put [:onerror e in={:error "throw"} do={}]           
# true

# wrong, since there still be a return value from :onerror
:put [:onerror e in={:error "throw"} do={:error "here"}]
# here

# also wrong, since return type should be bool
:put [:typeof [:onerror e in={:error "throw"} do={:error "here"}]]
# here
