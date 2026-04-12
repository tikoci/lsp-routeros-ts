# Source: https://forum.mikrotik.com/t/colon-or-not-to-colon/139477/12
# Topic: Colon or not to Colon
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

## using slash /

[amm0@MT] > /console/inspect request=syntax input="/put "

Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL     SYMBOL-TYPE  N  NON  TEXT                    
syntax             collection   0  yes                          
syntax  <message>  explanation  1  no   string or any expression

# using : colon

[amm0@MT] > /console/inspect request=syntax input=":put " path=ip,address 

Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL     SYMBOL-TYPE  N  NON  TEXT                    
syntax             collection   0  yes                          
syntax  <message>  explanation  1  no   string or any expression

# using / slash with a "path" of (/ip/address == ip,address ... in the /console/inspect) 

[amm0@MT] > /console/inspect request=syntax input="/put " path=ip,address 
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL     SYMBOL-TYPE  N  NON  TEXT                    
syntax             collection   0  yes                          
syntax  <message>  explanation  1  no   string or any expression


# BUT no / or : — a plain "put" is not valid if there is a path
/console/inspect request=syntax input="put " path=ip
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM
TYPE    SYMBOL        SYMBOL-TYPE  NESTED  NONORM
syntax                collection        0  yes   
syntax  ..            explanation       1  no    
syntax  address       explanation       1  no    
syntax  arp           explanation       1  no    
syntax  cloud         explanation       1  no    
syntax  dhcp-client   explanation       1  no    
[...]
