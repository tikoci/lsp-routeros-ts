# Source: https://forum.mikrotik.com/t/newb-in-scripting-getting-byte-value-from-lease-options-string/162848/2
# Post author: @rextended
# Extracted from: code-block

:global opt "0E26DEADBEEFDEADBEEFDEADBEEFDEADBEEFC0A86401"

:put [[:parse ":return 0x$[:pick $opt 0 2]"]]

:put [[:parse ":return 0x$[:pick $opt 2 4]"]]

:put (0.0.0.0 + [[:parse ":return 0x$[:pick $opt 36 44]"]])
