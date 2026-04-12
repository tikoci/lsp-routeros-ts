# Source: https://forum.mikrotik.com/t/sierra-mc7354-and-mc7455-showing-up-as-ppp-out1/160803/3
# Topic: Sierra MC7354 and MC7455 showing up as ppp-out1
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/ppp-client/set [find] data-channel=2 info-channel=2
/interface/ppp-client/at-chat [find] input="AT!ENTERCND=\"A710\"" 
/interface/ppp-client/at-chat [find] input="AT!UDUSBCOMP=8" 
/system/reboot
