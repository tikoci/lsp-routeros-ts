# Source: https://forum.mikrotik.com/t/tobool-not-working-as-expected/130860/6
# Topic: :tobool not working as expected
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global booltest [:tobool -1]
:put "booltest=$booltest using -1"
:global booltest [:tobool 0]
:put "booltest=$booltest using 0"
:global booltest [:tobool 1]
:put "booltest=$booltest using 1"
:global booltest [:tobool "1"]
:put "booltest=$booltest using \"1\" and returns typeof $([:typeof $booltest])"
:global booltest [:tobool [:tonum "1"]]
:put "booltest=$booltest using [tonum \"1\"] and returns typeof $([:typeof $booltest])"
