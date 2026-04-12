# Source: https://forum.mikrotik.com/t/find-vs-find/178856/4
# Topic: :find vs. find
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[admin@dude] > /console/inspect request=syntax path=find
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL  SYMBOL-TYPE  NESTED  NONORM  TEXT                           
syntax          collection        0  yes                                    
syntax  <in>    explanation       1  no      array or string value to search
syntax  <key>   explanation       1  no      value of key to find           
syntax  <from>  explanation       1  no      List of item numbers           
[admin@dude] > /console/inspect request=syntax path=ip,address,find
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM
TYPE    SYMBOL   SYMBOL-TYPE  NESTED  NONORM
syntax           collection        0  yes   
syntax  <where>  explanation       1  no
