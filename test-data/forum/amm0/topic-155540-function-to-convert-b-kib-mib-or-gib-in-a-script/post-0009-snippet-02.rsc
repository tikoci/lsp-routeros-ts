# Source: https://forum.mikrotik.com/t/function-to-convert-b-kib-mib-or-gib-in-a-script/155540/9
# Topic: Function to convert B, KiB, MiB or GiB in a script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
	# in a script, block, you can assign it to variable to then use in email script
	:local ltetx [$human [/interface get lte2 tx-byte]]
	:put $ltetx

	# alternatively in a string using interpolation
	:local strtxrx "TX is $([$human [/interface get lte2 tx-byte]] and RX is $([$human [/interface get lte2 rx-byte]])) 
}
