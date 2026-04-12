# Source: https://forum.mikrotik.com/t/static-dns-entries-first-adguard-second/165210/2
# Topic: static DNS-entries first, adguard second
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip dns static { :foreach h in=[find] do={
 :put "$[get $h address] $[get $h name]"
}}
