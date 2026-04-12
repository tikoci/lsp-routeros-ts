# Source: https://forum.mikrotik.com/t/frustrated-trying-to-create-a-script/169947/4
# Topic: Frustrated trying to create a script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global myarraymap {"key1"="text1";"key2"="text2"}
:global myarraylist ("str1","str2")
:global mystr "myglobalvar"
:put ($myarraylist.$mystr) 
        # output:     "str1myglobalvar;str2myglobalvar"
:put ($myarraymap.$mystr) 
        # outputs empty newline
