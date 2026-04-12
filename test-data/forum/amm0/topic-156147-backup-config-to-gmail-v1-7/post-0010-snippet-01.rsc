# Source: https://forum.mikrotik.com/t/backup-config-to-gmail-v1-7/156147/10
# Topic: Backup config to Gmail v1.7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global x do={:put "blah"}

# Version 7 it's ";evl(" that need to be :find 
/system script environment print detail where name=x
	# 3 name="x" value=";(evl (evl /putmessage=blah))" 

# But in Version 6, it's ";eval" that's @rextended uses
/system script environment print detail where name=x
	# 1 name="x" value=";(eval (eval /putmessage=blah))"
