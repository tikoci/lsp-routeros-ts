# Source: https://forum.mikrotik.com/t/catching-debug-log/264364/3
# Topic: Catching debug log
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:foreach fileid in=[/file/find name=$filename] do={
    :if ([/file/get $fileid size] > 0) do={...}
}
