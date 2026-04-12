# Source: https://forum.mikrotik.com/t/v7-17beta-testing-is-released/179003/341
# Topic: v7.17beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put "Press 'y' to continue, or any other key to abort"
:if ( [:convert from=num to=raw [/terminal/inkey]] != "y" ) do={ :error "script stopped by user" }
# more code after 'y' key ...
