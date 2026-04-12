# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/19
# Post author: @rextended
# Extracted from: code-block

:global hex2dec do={
    :local conv $1
    :if (!($conv~"^[0-9a-fA-F]+\$")) do={:return 0}
    :if ([:typeof [:find $conv "0x" -1]] = "nil") do={:set conv "0x$conv"}
    :return [:tonum $conv]
}
