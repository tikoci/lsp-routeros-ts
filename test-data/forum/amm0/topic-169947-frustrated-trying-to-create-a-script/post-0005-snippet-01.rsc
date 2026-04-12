# Source: https://forum.mikrotik.com/t/frustrated-trying-to-create-a-script/169947/5
# Topic: Frustrated trying to create a script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global myarraylist ("text1","text2")
:global myfunction do={:return "something $1 $0"}      
:put ($myarraylist.$myfunction)      
# text1;text1(code);text2;text2(code)                               
:put ($myarraylist.[$myfunction])
# text1something  $myfunction;text2something  $myfunction
