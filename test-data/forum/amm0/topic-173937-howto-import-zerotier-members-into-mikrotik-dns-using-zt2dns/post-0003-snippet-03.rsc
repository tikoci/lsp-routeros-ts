# Source: https://forum.mikrotik.com/t/howto-import-zerotier-members-into-mikrotik-dns-using-zt2dns/173937/3
# Topic: HOWTO:  Import ZeroTier Members into Mikrotik DNS using $ZT2DNS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
	# For "toss away" network I created to test this... 
	# 6PLANE in ZT Central show as "fcae:42c9:c1__:____:____:0000:0000:0001"
	# Network ID is:
:local net "ebe7fbd445a53215"
	# So doing the XOR as the docs explain, in RouterOS form:
:put [([:tonum "0x$[:pick $net 8 16]"]^[:tonum "0x$[:pick $net 0 8]"])]
# 2923612609

	# Since the "fc" is always the prefix for experimental, the relevant part is "ae:42c9:c1"
	# (should be calculated, so cheat to get it as a number from that str)
:put [:tonum "0xae42c9c1"] 
# 2923612609

# == it the same, so it the bits are same - just not in right format...

# ISSUE is new [:convert] cannot get a "hexstring" from a number...
# see @rextended's http://forum.mikrotik.com/t/how-to-covert-int-to-hex-type-value-and-save-it-in-a-string/52654/1 - so possible but a fair amount of other code is needed
# thus... cut-and-paste 6PLANE into command line, same as network=
}
