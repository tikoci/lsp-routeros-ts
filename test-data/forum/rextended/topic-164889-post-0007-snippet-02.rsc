# Source: https://forum.mikrotik.com/t/base64-and-sha256-function-for-scripting/164889/7
# Post author: @rextended
# Extracted from: code-block

[] > :put [$str2base32 "ManaM"]
JVQW4YKN

[] > :put [$str2base32 "Man"]
JVQW4===

[] > :put [$str2base32 "Man" "nopad"]
JVQW4

[] > :put [$str2base32 "ManaM" "hex"]
9LGMSOAD

[] > :put [$str2base32 "Man" "hex"]
9LGMS===

[] > :put [$str2base32 "Man" "hex" "nopad"]
9LGMS
