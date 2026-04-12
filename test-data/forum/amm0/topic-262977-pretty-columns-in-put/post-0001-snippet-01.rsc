# Source: https://forum.mikrotik.com/t/pretty-columns-in-put/262977/1
# Topic: 🎩 Pretty Columns in :put
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:for i from=0 to=10 do={ 
     :local rnd do={:return [:rndstr length=[:rndnum from=5 to=20]]}
     :local k "key-$[$rnd]"
     :local v "value $[$rnd]"
     :local m "#metadata?$[$rnd]"
     :put " $k \r\t\t\t $v \r\t\t\t\t\t\t $m" 
}
