# Source: https://forum.mikrotik.com/t/create-macro-or-small-script/262517/7
# Topic: Create Macro or small script?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global logallfirewall do={
    :if ($1="") do={:error "must provide 'yes' or 'no'"}
    /ip/firewall/filter/set [find dynamic=no] log=$1 log-prefix="$prefix"  
}
