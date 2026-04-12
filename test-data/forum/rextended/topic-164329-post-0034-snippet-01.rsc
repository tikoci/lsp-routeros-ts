# Source: https://forum.mikrotik.com/t/convert-any-text-to-unicode/164329/34
# Post author: @rextended
# Extracted from: code-block

:local repch "\FF\FD"
    :if ([:typeof $2] = "no-replace") do={:set repch ""}
