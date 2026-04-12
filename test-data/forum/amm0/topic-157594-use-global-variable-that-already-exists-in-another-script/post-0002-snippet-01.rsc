# Source: https://forum.mikrotik.com/t/use-global-variable-that-already-exists-in-another-script/157594/2
# Topic: Use global variable that already exists in another script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global stopRouterRun
:do {
           :delay 60
} while=(!$stopRouterRun)
