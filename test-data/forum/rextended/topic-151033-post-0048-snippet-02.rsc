# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/48
# Post author: @rextended
# Extracted from: code-block

[] > :put [$CP1252toHexGSM7 ("Hi to All! [@~)]")]
486920746F20416C6C21201B3C001B3D291B3E

# calculate characters needed, max single GSM7 SMS is 160 characters
[] > :put ([:len [$CP1252toHexGSM7 ("Hi to All! [@~)]")]] / 2)
19
