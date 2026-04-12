# Source: https://forum.mikrotik.com/t/how-to-get-value-from-json-string-using-scripts/264287/5
# Topic: How to get value from json string using scripts
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[admin@MikroTik] > {
:local url "http://yourserver.com/user.json"
:local fetchResult [/tool fetch url=$url output=user as-value]
:local username ""
:local password ""
:local profile ""
# ... more code
:if ([:typeof ($parsed->0)] != "nothing") do={
    :set username ($parsed->0)
    :set password ($parsed->1)
    :set profile ($parsed->2)
    }  
# ... rest of your code
} <enter>
[admin@MikroTik] >
