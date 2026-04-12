# Source: https://forum.mikrotik.com/t/convert-any-text-to-unicode/164329/33
# Topic: Convert any text to UNICODE
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:if ([:tostr $2] = "no-replace" || [:tostr $3] = "no-replace") do={:set repch ""}
 :local useutf16 0
 :if ([:tostr $2] = "as-utf16" || [:tostr $3] = "as-utf16") do={:set useutf16 1}
 # [...]
 :if ($useutf16) do={
 # your commented out code to deal with the "extra" part of UCS2
 }
