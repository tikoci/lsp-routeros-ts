# Source: https://forum.mikrotik.com/t/inquire-prompt-user-for-input-using-arrays-choices-qkeys/167956/1
# Topic: $INQUIRE - prompt user for input using arrays +$CHOICES +$QKEYS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

$INQUIRE ({
    {   text="Router name:"; 
        defval=(>[:return "$[/system/identity/get name]"]); 
        validate=(>[:if ([:tostr $0] ~ "^[a-zA-Z0-9_\\-]*\$" ) do={:return true} else={:return "invalid name"}]);
        action=(>[/system/identity/set name=$0]);
        key="sysid"
    }}) (>[:put "New system name is: $($1->"sysid")"]) as-value
