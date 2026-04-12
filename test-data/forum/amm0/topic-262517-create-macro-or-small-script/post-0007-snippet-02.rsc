# Source: https://forum.mikrotik.com/t/create-macro-or-small-script/262517/7
# Topic: Create Macro or small script?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global nologfirewall do={
    :global logallfirewall
    $logallfirewall no
}
