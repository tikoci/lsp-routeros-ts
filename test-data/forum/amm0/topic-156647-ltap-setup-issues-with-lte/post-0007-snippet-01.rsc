# Source: https://forum.mikrotik.com/t/ltap-setup-issues-with-lte/156647/7
# Topic: LtAP setup issues with LTE
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/dhcp-client/disable [find interface~"bridge"]
/interface/bridge/port/enable [find interface=ether1]
/interface/list/member/remove [/interface/list/member/find list=WAN interface=ether1]
