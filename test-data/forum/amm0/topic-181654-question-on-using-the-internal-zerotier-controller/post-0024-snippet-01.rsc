# Source: https://forum.mikrotik.com/t/question-on-using-the-internal-zerotier-controller/181654/24
# Topic: Question on using the Internal Zerotier Controller
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/zerotier/controller
# as array
set [find] routes=("2.0/24@10.1.1.1","17.0/8@10.1.1.1")
# or as string
set [find] routes="2.0/8@10.1.1.1,17.0/8@10.1.1.1"
# both forms work - so routes US military and Apple IPs to a ZT member at 10.1.1.1
# & resolve the 2.0 into 2.0.0.0, so that consistent at least (although still questionable in my book)
:put [get [find] routes]
2.0.0.0/8@10.1.1.1;17.0.0.0/8@10.1.1.1
