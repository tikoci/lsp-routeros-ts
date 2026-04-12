# Source: https://forum.mikrotik.com/t/howto-import-zerotier-members-into-mikrotik-dns-using-zt2dns/173937/4
# Topic: HOWTO:  Import ZeroTier Members into Mikrotik DNS using $ZT2DNS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# it's a number type, but to get build an IPv6 type, the hexstring is needed
    # num2hex converter (credit @rextended, http://forum.mikrotik.com/t/how-to-covert-int-to-hex-type-value-and-save-it-in-a-string/52654/1 )
 :local num2hex do={
        :local number  [:tonum $1]
        :local hexadec "0"
        :local remainder 0
        :local hexChars "0123456789ABCDEF"
        :if ($number > 0) do={:set hexadec ""}
        :while ( $number > 0 ) do={
                :set remainder ($number % 16)
                :set number (($number-$remainder) / 16)
                :set hexadec ([:pick $hexChars $remainder].$hexadec)
        } 
        :if ([:len $hexadec] = 1) do={:set hexadec "0$hexadec"}
        # return "0x$hexadec" - changed to remove "0x" part...
        :return "$hexadec"
    }
