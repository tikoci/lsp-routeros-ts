# Source: https://forum.mikrotik.com/t/question-on-using-the-internal-zerotier-controller/181654/29
# Topic: Question on using the Internal Zerotier Controller
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global clientztaddress "1fcfake1b8"
/zerotier/controller/member/add zt-address=$clientztaddress authorized=yes name=mymaczerotier disabled=no network=[../find disabled=no]    
:put "In ZeroTier client, use 'Join' with network of: $[[/zerotier/controller/get [/zerotier/controller/find disabled=no] network]]"
