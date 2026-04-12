# Source: https://forum.mikrotik.com/t/how-to-covert-int-to-hex-type-value-and-save-it-in-a-string/52654/6
# Post author: @rextended
# Extracted from: code-block

:global numbyte2hex do={
    :local input [:tonum $1]
    :local hexchars "0123456789ABCDEF"
    :local convert [:pick $hexchars (($input >> 4) & 0xF)]
    :set convert ($convert.[:pick $hexchars ($input & 0xF)])
    :return $convert
}
