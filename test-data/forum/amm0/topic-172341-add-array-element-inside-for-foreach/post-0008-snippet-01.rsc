# Source: https://forum.mikrotik.com/t/add-array-element-inside-for-foreach/172341/8
# Topic: Add array element inside for / foreach
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global interfaces [:toarray ""]
:foreach i in=(1,true,"three") do={ 
    :set interfaces ($interfaces,$i) 
}

:put $interfaces
# 1;true;three

:put [:len $interfaces]
# 3

:foreach j in=$interfaces do={ :put $j }
# 1
# true
# three
